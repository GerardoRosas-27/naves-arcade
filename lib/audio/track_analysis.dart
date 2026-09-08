/// Offline BGM analysis loaded from `assets/audio/analysis/*.json`.
class TrackAnalysis {
  const TrackAnalysis({
    required this.track,
    required this.duration,
    required this.bpm,
    required this.beatOffset,
    required this.energyHop,
    required this.energy,
    required this.beats,
    this.feel = '',
  });

  final String track;
  final double duration;
  final double bpm;
  final double beatOffset;
  final double energyHop;
  final List<double> energy;
  final List<double> beats;
  final String feel;

  double get beatPeriod => bpm > 0 ? 60.0 / bpm : 0.5;

  factory TrackAnalysis.fromJson(Map<String, dynamic> json) {
    return TrackAnalysis(
      track: json['track'] as String? ?? 'unknown',
      duration: (json['duration'] as num?)?.toDouble() ?? 0,
      bpm: (json['bpm'] as num?)?.toDouble() ?? 120,
      beatOffset: (json['beatOffset'] as num?)?.toDouble() ?? 0,
      energyHop: (json['energyHop'] as num?)?.toDouble() ?? 0.1,
      energy: (json['energy'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const <double>[0.5],
      beats: (json['beats'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const <double>[],
      feel: json['feel'] as String? ?? '',
    );
  }

  /// Linear sample of normalized RMS energy at [time] seconds.
  double energyAt(double time) {
    if (energy.isEmpty || energyHop <= 0) return 0.5;
    final idx = time / energyHop;
    if (idx <= 0) return energy.first;
    if (idx >= energy.length - 1) return energy.last;
    final i = idx.floor();
    final t = idx - i;
    return energy[i] * (1 - t) + energy[i + 1] * t;
  }

  /// True if [time] is within [window] seconds of a beat.
  bool nearBeat(double time, {double window = 0.08}) {
    if (beats.isEmpty) {
      final period = beatPeriod;
      if (period <= 0) return false;
      final phase = (time - beatOffset) % period;
      final d = phase < period / 2 ? phase : period - phase;
      return d <= window;
    }
    // Binary search nearest beat.
    var lo = 0;
    var hi = beats.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (beats[mid] < time) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    var best = (beats[lo] - time).abs();
    if (lo > 0) {
      best = best < (beats[lo - 1] - time).abs()
          ? best
          : (beats[lo - 1] - time).abs();
    }
    return best <= window;
  }
}
