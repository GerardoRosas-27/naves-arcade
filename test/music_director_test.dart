import 'package:flutter_test/flutter_test.dart';
import 'package:naves_arcade/audio/track_analysis.dart';

void main() {
  test('TrackAnalysis energyAt interpolates and clamps', () {
    final a = TrackAnalysis(
      track: 'bgm_test',
      duration: 2.0,
      bpm: 120,
      beatOffset: 0,
      energyHop: 0.5,
      energy: const [0.0, 1.0, 0.5, 0.25],
      beats: const [0.0, 0.5, 1.0, 1.5],
    );
    expect(a.energyAt(-1), 0.0);
    expect(a.energyAt(0), 0.0);
    expect(a.energyAt(0.25), closeTo(0.5, 1e-9));
    expect(a.energyAt(10), 0.25);
    expect(a.nearBeat(0.5, window: 0.08), isTrue);
    expect(a.nearBeat(0.3, window: 0.08), isFalse);
    expect(a.beatPeriod, closeTo(0.5, 1e-9));
  });

  test('TrackAnalysis.fromJson parses analysis shape', () {
    final a = TrackAnalysis.fromJson({
      'track': 'bgm_01',
      'duration': 10.5,
      'bpm': 100,
      'beatOffset': 0.1,
      'energyHop': 0.1,
      'energy': [0.2, 0.8],
      'beats': [0.1, 0.7],
      'feel': 'test',
    });
    expect(a.track, 'bgm_01');
    expect(a.energyAt(0.05), closeTo(0.5, 1e-9));
    expect(a.feel, 'test');
  });
}
