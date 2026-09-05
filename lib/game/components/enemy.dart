import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../naves_game.dart';
import 'bullet.dart';

enum EnemyKind { scout, tank, zig }

class Enemy extends PositionComponent
    with CollisionCallbacks, HasGameReference<NavesGame> {
  Enemy({
    required Vector2 position,
    required this.kind,
    required this.speed,
  }) : super(
          position: position,
          size: kind == EnemyKind.tank ? Vector2(40, 36) : Vector2(30, 28),
          anchor: Anchor.center,
          priority: 5,
        );

  final EnemyKind kind;
  final double speed;
  double _phase = Random().nextDouble() * pi * 2;

  Color get neonColor {
    switch (kind) {
      case EnemyKind.scout:
        return const Color(0xFFFF4081);
      case EnemyKind.tank:
        return const Color(0xFFFFAB00);
      case EnemyKind.zig:
        return const Color(0xFFE040FB);
    }
  }

  int get pointValue {
    switch (kind) {
      case EnemyKind.scout:
        return 100;
      case EnemyKind.tank:
        return 200;
      case EnemyKind.zig:
        return 150;
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: size.x * 0.4));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 3;

    switch (kind) {
      case EnemyKind.scout:
        position.y += speed * dt;
      case EnemyKind.tank:
        position.y += speed * 0.7 * dt;
      case EnemyKind.zig:
        position.y += speed * dt;
        position.x += sin(_phase) * 90 * dt;
    }

    if (position.y > game.playArea.y + 40) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final color = neonColor;

    canvas.drawCircle(
      Offset(cx, cy),
      size.x * 0.45,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    final path = Path();
    if (kind == EnemyKind.tank) {
      path
        ..moveTo(cx, size.y - 2)
        ..lineTo(size.x - 2, 8)
        ..lineTo(cx + 8, 2)
        ..lineTo(cx - 8, 2)
        ..lineTo(2, 8)
        ..close();
    } else {
      path
        ..moveTo(cx, size.y - 2)
        ..lineTo(size.x - 2, 4)
        ..lineTo(cx, 10)
        ..lineTo(2, 4)
        ..close();
    }

    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.85));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFFFFFFF),
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Bullet) {
      other.removeFromParent();
      removeFromParent();
      game.onEnemyKilled(this);
    }
  }
}
