import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../naves_game.dart';

/// Hostile projectile. Optional [spin] rotates velocity for spiral patterns.
class EnemyBullet extends PositionComponent
    with HasGameReference<NavesGame>, CollisionCallbacks {
  EnemyBullet({
    required Vector2 position,
    required Vector2 velocity,
    this.spin = 0,
    this.tint = const Color(0xFFFF4081),
  }) : velocity = velocity.clone(),
       super(
          position: position,
          size: Vector2(6, 6),
          anchor: Anchor.center,
          priority: 7,
        );

  Vector2 velocity;
  final double spin;
  final Color tint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: 3));
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Bruster: N slow wave does not affect enemy bullets (only ships).
    if (spin != 0) {
      final angle = atan2(velocity.y, velocity.x) + spin * dt;
      final speed = velocity.length;
      velocity = Vector2(cos(angle), sin(angle)) * speed;
    }
    position += velocity * dt;
    if (position.y < -30 ||
        position.y > game.playArea.y + 30 ||
        position.x < -30 ||
        position.x > game.playArea.x + 30) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(
      c,
      5,
      Paint()
        ..color = tint.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(c, 2.5, Paint()..color = tint);
    canvas.drawCircle(c, 1.2, Paint()..color = const Color(0xFFFFFFFF));
  }
}
