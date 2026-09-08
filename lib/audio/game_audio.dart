import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Background music playlist + weapon SFX for Naves Arcade.
///
/// BGM starts after a user gesture (¡JUGAR!) so web autoplay policies allow it.
/// Tracks advance on completion and wrap to the first after the last.
class GameAudio {
  GameAudio._();

  static final GameAudio instance = GameAudio._();

  static const List<String> _bgmPlaylist = [
    'bgm/bgm_01.mp3',
    'bgm/bgm_02.mp3',
    'bgm/bgm_03.mp3',
    'bgm/bgm_04.mp3',
  ];

  static const String shootNormal = 'sfx/shoot_normal.mp3';
  static const String shootBurst = 'sfx/shoot_burst.mp3';
  static const String shootMulti = 'sfx/shoot_multi.mp3';

  AudioPlayer? _bgm;
  StreamSubscription<void>? _completeSub;
  int _trackIndex = 0;
  bool _playlistActive = false;
  bool _userPaused = false;
  bool _ready = false;

  Future<void> ensureLoaded() async {
    if (_ready) return;
    try {
      await FlameAudio.audioCache.loadAll([
        ..._bgmPlaylist,
        shootNormal,
        shootBurst,
        shootMulti,
      ]);
      _ready = true;
    } catch (e, st) {
      debugPrint('GameAudio load failed: $e\n$st');
    }
  }

  /// Call from the ¡JUGAR! tap (or restart) so browsers unlock audio.
  Future<void> startPlaylist() async {
    await ensureLoaded();
    _userPaused = false;
    if (_playlistActive && _bgm != null) {
      await resume();
      return;
    }
    _playlistActive = true;
    _trackIndex = 0;
    await _ensurePlayer();
    await _playCurrentTrack();
  }

  Future<void> _ensurePlayer() async {
    if (_bgm != null) return;
    final player = AudioPlayer();
    player.audioCache = FlameAudio.audioCache;
    await player.setReleaseMode(ReleaseMode.release);
    await player.setVolume(0.4);
    _completeSub = player.onPlayerComplete.listen((_) {
      unawaited(_onTrackComplete());
    });
    _bgm = player;
  }

  Future<void> _playCurrentTrack() async {
    final player = _bgm;
    if (player == null || !_playlistActive || _userPaused) return;
    final track = _bgmPlaylist[_trackIndex % _bgmPlaylist.length];
    try {
      await player.stop();
      await player.play(AssetSource(track));
    } catch (e, st) {
      debugPrint('GameAudio BGM play failed ($track): $e\n$st');
    }
  }

  Future<void> _onTrackComplete() async {
    if (!_playlistActive || _userPaused) return;
    _trackIndex = (_trackIndex + 1) % _bgmPlaylist.length;
    await _playCurrentTrack();
  }

  Future<void> pause() async {
    _userPaused = true;
    try {
      await _bgm?.pause();
    } catch (e) {
      debugPrint('GameAudio pause failed: $e');
    }
  }

  Future<void> resume() async {
    if (!_playlistActive) {
      await startPlaylist();
      return;
    }
    _userPaused = false;
    final player = _bgm;
    if (player == null) {
      await _ensurePlayer();
      await _playCurrentTrack();
      return;
    }
    try {
      final state = player.state;
      if (state == PlayerState.paused) {
        await player.resume();
      } else if (state != PlayerState.playing) {
        await _playCurrentTrack();
      }
    } catch (e) {
      debugPrint('GameAudio resume failed: $e');
    }
  }

  Future<void> stop() async {
    _playlistActive = false;
    _userPaused = false;
    try {
      await _bgm?.stop();
    } catch (e) {
      debugPrint('GameAudio stop failed: $e');
    }
  }

  Future<void> playShoot({
    required bool multiShot,
    required bool burstMode,
  }) async {
    final file = multiShot
        ? shootMulti
        : burstMode
            ? shootBurst
            : shootNormal;
    try {
      await FlameAudio.play(file, volume: 0.55);
    } catch (e) {
      debugPrint('GameAudio SFX failed ($file): $e');
    }
  }

  Future<void> dispose() async {
    await _completeSub?.cancel();
    _completeSub = null;
    await _bgm?.dispose();
    _bgm = null;
    _playlistActive = false;
    _userPaused = false;
  }
}
