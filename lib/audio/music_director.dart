import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'game_audio.dart';
import 'track_analysis.dart';

/// How enemy ships fire — switched live by [MusicDirector].
enum FirePattern { straight, fan, spiral }

/// Live gameplay cue derived from pre-analyzed BGM + playback position.
class MusicCue {
  const MusicCue({
    this.act = 1,
    this.energy = 0.45,
    this.spawnInterval = 1.0,
    this.speedScale = 1.0,
    this.waveChance = 0.15,
    this.tankBias = 0.2,
    this.firePattern = FirePattern.straight,
    this.fireOnBeatOnly = false,
    this.onBeat = false,
    this.sectionEnding = false,
    this.scrollScale = 1.0,
  });

  final int act;
  final double energy;
  final double spawnInterval;
  final double speedScale;
  final double waveChance;
  final double tankBias;
  final FirePattern firePattern;
  final bool fireOnBeatOnly;
  final bool onBeat;
  final bool sectionEnding;
  final double scrollScale;

  static const idle = MusicCue();
}

/// Per-track “act” personality layered on top of the energy envelope.
class _ActProfile {
  const _ActProfile({
    required this.baseInterval,
    required this.minInterval,
    required this.speedMul,
    required this.tankBias,
    required this.preferred,
    required this.beatFireEmphasis,
  });

  final double baseInterval;
  final double minInterval;
  final double speedMul;
  final double tankBias;
  final FirePattern preferred;
  final bool beatFireEmphasis;
}

/// Reads offline analysis JSON + [GameAudio] position and drives the game.
///
/// Pre-analysis (not live FFT) keeps Flutter web reliable while still making
/// the game “dance” with RMS energy and an approximate beat grid.
class MusicDirector {
  MusicDirector._();

  static final MusicDirector instance = MusicDirector._();

  static const _assetPaths = [
    'assets/audio/analysis/bgm_01.json',
    'assets/audio/analysis/bgm_02.json',
    'assets/audio/analysis/bgm_03.json',
    'assets/audio/analysis/bgm_04.json',
  ];

  static const _acts = [
    // Act 1 — apertura: fan / straight, medium density
    _ActProfile(
      baseInterval: 1.15,
      minInterval: 0.42,
      speedMul: 0.95,
      tankBias: 0.18,
      preferred: FirePattern.fan,
      beatFireEmphasis: true,
    ),
    // Act 2 — pulso corto agresivo
    _ActProfile(
      baseInterval: 0.85,
      minInterval: 0.28,
      speedMul: 1.25,
      tankBias: 0.12,
      preferred: FirePattern.spiral,
      beatFireEmphasis: false,
    ),
    // Act 3 — contraste: beat-synced shots in lulls
    _ActProfile(
      baseInterval: 1.05,
      minInterval: 0.35,
      speedMul: 0.9,
      tankBias: 0.22,
      preferred: FirePattern.straight,
      beatFireEmphasis: true,
    ),
    // Act 4 — clímax
    _ActProfile(
      baseInterval: 0.75,
      minInterval: 0.25,
      speedMul: 1.2,
      tankBias: 0.32,
      preferred: FirePattern.fan,
      beatFireEmphasis: false,
    ),
  ];

  final List<TrackAnalysis?> _tracks = List.filled(4, null);
  bool _ready = false;
  bool _sectionEnding = false;
  MusicCue cue = MusicCue.idle;

  bool get isReady => _ready;
  bool get sectionEnding => _sectionEnding;

  Future<void> ensureLoaded() async {
    if (_ready) return;
    for (var i = 0; i < _assetPaths.length; i++) {
      try {
        final raw = await rootBundle.loadString(_assetPaths[i]);
        _tracks[i] =
            TrackAnalysis.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (e, st) {
        debugPrint('MusicDirector load failed (${_assetPaths[i]}): $e\n$st');
      }
    }
    _ready = true;
  }

  TrackAnalysis? analysisFor(int trackIndex) {
    if (trackIndex < 0 || trackIndex >= _tracks.length) return null;
    return _tracks[trackIndex];
  }

  String feelFor(int trackIndex) => analysisFor(trackIndex)?.feel ?? '';

  void beginSectionEnd() {
    _sectionEnding = true;
    cue = cue.copyWith(sectionEnding: true, spawnInterval: 99, waveChance: 0);
  }

  void beginAct(int trackIndex) {
    _sectionEnding = false;
    // Force refresh on next tick with new act defaults.
    final profile = _acts[trackIndex % _acts.length];
    cue = MusicCue(
      act: trackIndex % _acts.length + 1,
      energy: 0.4,
      spawnInterval: profile.baseInterval,
      speedScale: profile.speedMul,
      tankBias: profile.tankBias,
      firePattern: profile.preferred,
      fireOnBeatOnly: profile.beatFireEmphasis,
    );
  }

  /// Call once per game tick while playing.
  void update() {
    if (!_ready || _sectionEnding) return;

    final audio = GameAudio.instance;
    final idx = audio.trackIndex % _acts.length;
    final profile = _acts[idx];
    final analysis = _tracks[idx];
    final t = audio.positionSeconds;

    final energy = analysis?.energyAt(t) ?? 0.45;
    final onBeat = analysis?.nearBeat(t) ?? false;

    // High energy → denser / faster; low energy → slower but beat-synced fire.
    final spawnInterval = (profile.baseInterval -
            energy * (profile.baseInterval - profile.minInterval))
        .clamp(profile.minInterval, profile.baseInterval);
    final speedScale = profile.speedMul * (0.75 + energy * 0.55);
    final waveChance = 0.08 + energy * 0.28;

    FirePattern pattern;
    if (energy > 0.72) {
      pattern = energy > 0.88 ? FirePattern.spiral : profile.preferred;
      if (profile.preferred == FirePattern.spiral) {
        pattern = FirePattern.spiral;
      } else if (energy > 0.82) {
        pattern = FirePattern.fan;
      }
    } else if (energy < 0.38) {
      pattern = FirePattern.straight;
    } else {
      pattern = profile.preferred;
    }

    final fireOnBeatOnly =
        profile.beatFireEmphasis && energy < 0.48;

    cue = MusicCue(
      act: idx + 1,
      energy: energy,
      spawnInterval: spawnInterval,
      speedScale: speedScale,
      waveChance: waveChance,
      tankBias: profile.tankBias * (0.7 + energy * 0.6),
      firePattern: pattern,
      fireOnBeatOnly: fireOnBeatOnly,
      onBeat: onBeat,
      sectionEnding: false,
      scrollScale: 0.85 + energy * 0.5,
    );
  }
}

extension on MusicCue {
  MusicCue copyWith({
    int? act,
    double? energy,
    double? spawnInterval,
    double? speedScale,
    double? waveChance,
    double? tankBias,
    FirePattern? firePattern,
    bool? fireOnBeatOnly,
    bool? onBeat,
    bool? sectionEnding,
    double? scrollScale,
  }) {
    return MusicCue(
      act: act ?? this.act,
      energy: energy ?? this.energy,
      spawnInterval: spawnInterval ?? this.spawnInterval,
      speedScale: speedScale ?? this.speedScale,
      waveChance: waveChance ?? this.waveChance,
      tankBias: tankBias ?? this.tankBias,
      firePattern: firePattern ?? this.firePattern,
      fireOnBeatOnly: fireOnBeatOnly ?? this.fireOnBeatOnly,
      onBeat: onBeat ?? this.onBeat,
      sectionEnding: sectionEnding ?? this.sectionEnding,
      scrollScale: scrollScale ?? this.scrollScale,
    );
  }
}
