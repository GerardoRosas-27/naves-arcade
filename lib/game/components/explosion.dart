import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

class _Particle {
  _Particle(this.pos, this.vel, this.life, this.size);

  Vector2 pos;
  Vector2 vel;
  double life;
  double size;
}

class Explosion extends PositionComponent {
  Explosion({
    required Vector2 position,
    required this.color,
    this.intensity = 1,
  }) : super(
          position: position,
          size: Vector2.all(1),
          anchor: Anchor.center,
          priority: 20,
        );

  final Color color;
  final double intensity;

  final _rng = Random();
  final _particles = <_Particle>[];
  double _life = 0.45;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final count = (18 * intensity).round();
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 40 + _rng.nextDouble() * 160 * intensity;
      _particles.add(
        _Particle(
          Vector2.zero(),
          Vector2(cos(angle), sin(angle)) * speed,
          0.25 + _rng.nextDouble() * 0.35,
          2 + _rng.nextDouble() * 4 * intensity,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    for (final p in _particles) {
      p.pos += p.vel * dt;
      p.vel *= 0.96;
      p.life -= dt;
    }
    if (_life <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_life / 0.45).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset.zero,
      20 * intensity * (1 - t + 0.2),
      Paint()
        ..color = color.withValues(alpha: 0.35 * t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    for (final p in _particles) {
      if (p.life <= 0) continue;
      final a = (p.life / 0.4).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(p.pos.x, p.pos.y),
        p.size * a,
        Paint()..color = color.withValues(alpha: a),
      );
    }
  }
}
