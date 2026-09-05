import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../naves_game.dart';

enum PowerUpType { burst, shield, multiShot }

class PowerUp extends PositionComponent
    with CollisionCallbacks, HasGameReference<NavesGame> {
  PowerUp({
    required Vector2 position,
    required this.type,
  }) : super(
          position: position,
          size: Vector2.all(28),
          anchor: Anchor.center,
          priority: 6,
        );

  final PowerUpType type;
  double _spin = 0;

  factory PowerUp.random({
    required Vector2 position,
    required Random rng,
  }) {
    final types = PowerUpType.values;
    return PowerUp(
      position: position,
      type: types[rng.nextInt(types.length)],
    );
  }

  Color get color {
    switch (type) {
      case PowerUpType.burst:
        return const Color(0xFFFFAB00);
      case PowerUpType.shield:
        return const Color(0xFF00E5FF);
      case PowerUpType.multiShot:
        return const Color(0xFFE040FB);
    }
  }

  String get label {
    switch (type) {
      case PowerUpType.burst:
        return 'R';
      case PowerUpType.shield:
        return 'E';
      case PowerUpType.multiShot:
        return 'M';
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _spin += dt * 4;
    position.y += 60 * dt;
    position.x += sin(_spin) * 20 * dt;
    if (position.y > game.size.y + 30) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(
      c,
      14,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      c,
      12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
    canvas.drawCircle(c, 10, Paint()..color = color.withValues(alpha: 0.35));

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
  }
}
