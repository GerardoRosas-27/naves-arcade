import 'dart:math';

import 'package:flame/components.dart';

import '../../audio/music_director.dart';
import '../components/enemy.dart';
import '../naves_game.dart';

class SpawnManager extends Component with HasGameReference<NavesGame> {
  final _rng = Random();
  double _timer = 1.2;
  double _elapsed = 0;
  bool pausedForSection = false;

  void reset() {
    _timer = 1.0;
    _elapsed = 0;
    pausedForSection = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isPaused || game.isGameOver || pausedForSection) return;

    _elapsed += dt;
    _timer -= dt;

    final cue = MusicDirector.instance.cue;
    if (_timer <= 0) {
      _spawn(cue);
      final jitter = 0.7 + _rng.nextDouble() * 0.6;
      _timer = cue.spawnInterval * jitter;
    }
  }

  void _spawn(MusicCue cue) {
    final w = game.playArea.x;
    final x = 30 + _rng.nextDouble() * (w - 60);
    final roll = _rng.nextDouble();

    EnemyKind kind;
    double baseSpeed;
    final tankChance = 0.12 + cue.tankBias * 0.5;
    final zigChance = 0.25;

    if (roll < tankChance) {
      kind = EnemyKind.tank;
      baseSpeed = 80 + _elapsed * 1.2;
    } else if (roll < tankChance + zigChance) {
      kind = EnemyKind.zig;
      baseSpeed = 100 + _elapsed * 1.8;
    } else {
      kind = EnemyKind.scout;
      baseSpeed = 110 + _elapsed * 2.2;
    }

    final speed = (baseSpeed + _rng.nextDouble() * 20) * cue.speedScale;

    final count = _rng.nextDouble() < cue.waveChance ? 3 : 1;
    for (var i = 0; i < count; i++) {
      final ox = (i - (count - 1) / 2) * 40;
      game.world.add(
        Enemy(
          position: Vector2((x + ox).clamp(24, w - 24), -30.0 - i * 28),
          kind: kind,
          speed: speed,
          firePattern: cue.firePattern,
        ),
      );
    }
  }
}
