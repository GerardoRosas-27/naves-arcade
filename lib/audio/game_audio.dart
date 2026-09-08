import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Background music playlist + weapon SFX for Naves Arcade.
///
/// BGM and SFX use **isolated** players/pools so weapon sounds never advance
/// the playlist and track changes never duck/mix into SFX channels.
/// BGM starts after a user gesture (¡JUGAR!) so web autoplay policies allow it.
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
  static const String shieldWave = 'sfx/shield_wave.mp3';
  static const String destroyWave = 'sfx/destroy_wave.mp3';
  static const String noCharge = 'sfx/no_charge.mp3';

  /// Shared audio context: mix with others so SFX never steal BGM focus.
  static final AudioContext _mixCtx = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  AudioPlayer? _bgm;
  AudioPool? _poolNormal;
  AudioPool? _poolBurst;
  AudioPool? _poolMulti;
  AudioPool? _poolShield;
  AudioPool? _poolDestroy;
  AudioPool? _poolNoCharge;
  StreamSubscription<void>? _completeSub;
  StreamSubscription<Duration>? _positionSub;
  int _trackIndex = 0;
  bool _playlistActive = false;
  bool _userPaused = false;
  bool _ready = false;
  bool _sfxReady = false;
  /// When true, [onPlayerComplete] from intentional stop/seek is ignored.
  bool _ignoreComplete = false;
  double _positionSeconds = 0;

  /// Optional hook when a track ends (before the next starts).
  Future<void> Function(int completedIndex, int nextIndex)? onSectionBoundary;

  int get trackIndex => _trackIndex;
  int get trackCount => _bgmPlaylist.length;
  double get positionSeconds => _positionSeconds;
  bool get isPlaylistActive => _playlistActive;

  Future<void> ensureLoaded() async {
    if (_ready) return;
    try {
      await FlameAudio.audioCache.loadAll([
        ..._bgmPlaylist,
        shootNormal,
        shootBurst,
        shootMulti,
        shieldWave,
        destroyWave,
        noCharge,
      ]);
      _ready = true;
    } catch (e, st) {
      debugPrint('GameAudio load failed: $e\n$st');
    }
  }

  Future<void> _ensureSfxPools() async {
    if (_sfxReady) return;
    await ensureLoaded();
    try {
      _poolNormal = await FlameAudio.createPool(
        shootNormal,
        minPlayers: 1,
        maxPlayers: 4,
        audioContext: _mixCtx,
      );
      _poolBurst = await FlameAudio.createPool(
        shootBurst,
        minPlayers: 1,
        maxPlayers: 4,
        audioContext: _mixCtx,
      );
      _poolMulti = await FlameAudio.createPool(
        shootMulti,
        minPlayers: 1,
        maxPlayers: 4,
        audioContext: _mixCtx,
      );
      _poolShield = await FlameAudio.createPool(
        shieldWave,
        minPlayers: 1,
        maxPlayers: 2,
        audioContext: _mixCtx,
      );
      _poolDestroy = await FlameAudio.createPool(
        destroyWave,
        minPlayers: 1,
        maxPlayers: 2,
        audioContext: _mixCtx,
      );
      _poolNoCharge = await FlameAudio.createPool(
        noCharge,
        minPlayers: 1,
        maxPlayers: 2,
        audioContext: _mixCtx,
      );
      _sfxReady = true;
    } catch (e, st) {
      debugPrint('GameAudio SFX pools failed: $e\n$st');
    }
  }

  /// Call from the ¡JUGAR! tap (or restart) so browsers unlock audio.
  Future<void> startPlaylist() async {
    await ensureLoaded();
    await _ensureSfxPools();
    _userPaused = false;
    if (_playlistActive && _bgm != null) {
      await resume();
      return;
    }
    _playlistActive = true;
    _trackIndex = 0;
    _positionSeconds = 0;
    await _ensurePlayer();
    await _playCurrentTrack();
  }

  Future<void> _ensurePlayer() async {
    if (_bgm != null) return;
    final player = AudioPlayer();
    player.audioCache = FlameAudio.audioCache;
    await player.setPlayerMode(PlayerMode.mediaPlayer);
    await player.setReleaseMode(ReleaseMode.release);
    await player.setVolume(0.4);
    await player.setAudioContext(_mixCtx);
    _completeSub = player.onPlayerComplete.listen((_) {
      if (_ignoreComplete) return;
      unawaited(_onTrackComplete());
    });
    _positionSub = player.onPositionChanged.listen((pos) {
      _positionSeconds = pos.inMilliseconds / 1000.0;
    });
    _bgm = player;
  }

  Future<void> _playCurrentTrack() async {
    final player = _bgm;
    if (player == null || !_playlistActive || _userPaused) return;
    final track = _bgmPlaylist[_trackIndex % _bgmPlaylist.length];
    _positionSeconds = 0;
    _ignoreComplete = true;
    try {
      await player.stop();
      await player.play(
        AssetSource(track),
        volume: 0.4,
        mode: PlayerMode.mediaPlayer,
        ctx: _mixCtx,
      );
    } catch (e, st) {
      debugPrint('GameAudio BGM play failed ($track): $e\n$st');
    } finally {
      // Allow the event loop to flush any complete event from stop().
      await Future<void>.delayed(Duration.zero);
      _ignoreComplete = false;
    }
  }

  Future<void> _onTrackComplete() async {
    if (!_playlistActive || _userPaused || _ignoreComplete) return;
    final completed = _trackIndex;
    final next = (_trackIndex + 1) % _bgmPlaylist.length;
    final boundary = onSectionBoundary;
    if (boundary != null) {
      try {
        await boundary(completed, next);
      } catch (e, st) {
        debugPrint('GameAudio section boundary failed: $e\n$st');
      }
    }
    if (!_playlistActive || _userPaused || _ignoreComplete) return;
    _trackIndex = next;
    _positionSeconds = 0;
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
    _positionSeconds = 0;
    _ignoreComplete = true;
    try {
      await _bgm?.stop();
    } catch (e) {
      debugPrint('GameAudio stop failed: $e');
    } finally {
      await Future<void>.delayed(Duration.zero);
      _ignoreComplete = false;
    }
  }

  /// Weapon SFX only — never touches the BGM player or playlist.
  Future<void> playShoot({
    required bool multiShot,
    required bool burstMode,
  }) async {
    await _ensureSfxPools();
    final pool = multiShot
        ? _poolMulti
        : burstMode
            ? _poolBurst
            : _poolNormal;
    try {
      await pool?.start(volume: 0.55);
    } catch (e) {
      debugPrint('GameAudio SFX failed: $e');
    }
  }

  /// Mechanic A SFX — isolated pool, never touches BGM.
  Future<void> playShieldWave() async {
    await _ensureSfxPools();
    try {
      await _poolShield?.start(volume: 0.4);
    } catch (e) {
      debugPrint('GameAudio shield SFX failed: $e');
    }
  }

  /// Mechanic B SFX — isolated pool, never touches BGM.
  Future<void> playDestroyWave() async {
    await _ensureSfxPools();
    try {
      await _poolDestroy?.start(volume: 0.45);
    } catch (e) {
      debugPrint('GameAudio destroy SFX failed: $e');
    }
  }

  Future<void> playNoCharge() async {
    await _ensureSfxPools();
    try {
      await _poolNoCharge?.start(volume: 0.3);
    } catch (e) {
      debugPrint('GameAudio no-charge SFX failed: $e');
    }
  }

  Future<void> dispose() async {
    await _completeSub?.cancel();
    _completeSub = null;
    await _positionSub?.cancel();
    _positionSub = null;
    _ignoreComplete = true;
    try {
      await _bgm?.dispose();
    } catch (_) {}
    _bgm = null;
    await _poolNormal?.dispose();
    await _poolBurst?.dispose();
    await _poolMulti?.dispose();
    await _poolShield?.dispose();
    await _poolDestroy?.dispose();
    await _poolNoCharge?.dispose();
    _poolNormal = null;
    _poolBurst = null;
    _poolMulti = null;
    _poolShield = null;
    _poolDestroy = null;
    _poolNoCharge = null;
    _sfxReady = false;
    _playlistActive = false;
    _userPaused = false;
    onSectionBoundary = null;
    _ignoreComplete = false;
  }
}
