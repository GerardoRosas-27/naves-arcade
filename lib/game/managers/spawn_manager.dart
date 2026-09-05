import 'dart:math';

import 'package:flame/components.dart';

import '../components/enemy.dart';
import '../naves_game.dart';

class SpawnManager extends Component with HasGameReference<NavesGame> {
  final _rng = Random();
  double _timer = 1.2;
  double _elapsed = 0;
  double _interval = 1.1;

  void reset() {
    _timer = 1.0;
    _elapsed = 0;
    _interval = 1.1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isPaused || game.isGameOver) return;

    _elapsed += dt;
    _timer -= dt;

    // Ramp difficulty
    _interval = max(0.35, 1.1 - _elapsed * 0.015);

    if (_timer <= 0) {
      _spawn();
      _timer = _interval * (0.7 + _rng.nextDouble() * 0.6);
    }
  }

  void _spawn() {
    final w = game.playArea.x;
    final x = 30 + _rng.nextDouble() * (w - 60);
    final roll = _rng.nextDouble();

    EnemyKind kind;
    double speed;
    if (roll < 0.55) {
      kind = EnemyKind.scout;
      speed = 110 + _elapsed * 3;
    } else if (roll < 0.8) {
      kind = EnemyKind.zig;
      speed = 100 + _elapsed * 2.5;
    } else {
      kind = EnemyKind.tank;
      speed = 80 + _elapsed * 2;
    }

    // Occasional wave
    final count = _rng.nextDouble() < 0.2 ? 3 : 1;
    for (var i = 0; i < count; i++) {
      final ox = (i - (count - 1) / 2) * 40;
      game.world.add(
        Enemy(
          position: Vector2((x + ox).clamp(24, w - 24), -30.0 - i * 28),
          kind: kind,
          speed: speed + _rng.nextDouble() * 20,
        ),
      );
    }
  }
}
