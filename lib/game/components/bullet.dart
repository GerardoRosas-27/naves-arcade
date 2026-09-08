import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../naves_game.dart';

class Bullet extends PositionComponent
    with HasGameReference<NavesGame>, CollisionCallbacks {
  Bullet({
    required Vector2 position,
    required this.velocity,
  }) : super(
          position: position,
          size: Vector2(4, 14),
          anchor: Anchor.center,
          priority: 8,
        );

  final Vector2 velocity;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Mechanic A: player bullets also slow inside the slow wave.
    final scale = game.projectileTimeScaleAt(position);
    position += velocity * dt * scale;
    if (position.y < -20 ||
        position.y > game.playArea.y + 20 ||
        position.x < -20 ||
        position.x > game.playArea.x + 20) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFF00E5FF)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(size.x / 2, 0),
      4,
      Paint()
        ..color = const Color(0x6600E5FF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }
}
