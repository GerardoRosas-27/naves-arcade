import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../naves_game.dart';
import 'enemy.dart';
import 'enemy_bullet.dart';
import 'power_up.dart';

class PlayerShip extends PositionComponent
    with CollisionCallbacks, HasGameReference<NavesGame> {
  PlayerShip()
      : super(
          size: Vector2(36, 44),
          anchor: Anchor.center,
          priority: 10,
        );

  Vector2 joystickDelta = Vector2.zero();
  Vector2 keyboardDelta = Vector2.zero();
  Vector2? dragTarget;

  bool hasShield = false;
  bool burstMode = false;
  bool multiShot = false;

  double _shieldTimer = 0;
  double _burstTimer = 0;
  double _multiTimer = 0;
  double _invuln = 0;
  double _blink = 0;

  double get fireRate {
    if (burstMode) return 0.09;
    if (multiShot) return 0.16;
    return 0.18;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(game.playArea.x / 2, game.playArea.y * 0.78);
    add(CircleHitbox(radius: 14, isSolid: true));
  }

  void resetState() {
    position = Vector2(game.playArea.x / 2, game.playArea.y * 0.78);
    hasShield = false;
    burstMode = false;
    multiShot = false;
    _shieldTimer = 0;
    _burstTimer = 0;
    _multiTimer = 0;
    _invuln = 1.5;
    joystickDelta = Vector2.zero();
    keyboardDelta = Vector2.zero();
    dragTarget = null;
  }

  void respawn() {
    position = Vector2(game.playArea.x / 2, game.playArea.y * 0.82);
    _invuln = 2.0;
  }

  void activateShield() {
    hasShield = true;
    _shieldTimer = 8;
  }

  void breakShield() {
    hasShield = false;
    _shieldTimer = 0;
    _invuln = 0.8;
  }

  void activateBurst() {
    burstMode = true;
    _burstTimer = 7;
  }

  void activateMultiShot() {
    multiShot = true;
    _multiTimer = 8;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_invuln > 0) _invuln -= dt;
    _blink += dt * 12;

    if (_shieldTimer > 0) {
      _shieldTimer -= dt;
      if (_shieldTimer <= 0) hasShield = false;
    }
    if (_burstTimer > 0) {
      _burstTimer -= dt;
      if (_burstTimer <= 0) burstMode = false;
    }
    if (_multiTimer > 0) {
      _multiTimer -= dt;
      if (_multiTimer <= 0) multiShot = false;
    }

    final speed = 280.0;
    // Joystick + teclado (WASD) se combinan; el arrastre solo si no hay input direccional.
    final move = joystickDelta + keyboardDelta;
    if (move.length2 > 0.01) {
      position += move.normalized() * speed * dt;
    } else if (dragTarget != null) {
      final delta = dragTarget! - position;
      if (delta.length > 4) {
        position += delta.normalized() * min(speed * dt, delta.length);
      }
    }

    position.x = position.x.clamp(20, game.playArea.x - 20);
    position.y = position.y.clamp(60, game.playArea.y - 40);
  }

  @override
  void render(Canvas canvas) {
    if (_invuln > 0 && sin(_blink) < 0) return;

    final cx = size.x / 2;
    final cy = size.y / 2;

    // Engine glow
    final glow = Paint()
      ..color = const Color(0x8800E5FF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(cx, cy + 16), 8, glow);

    final body = Path()
      ..moveTo(cx, 2)
      ..lineTo(cx + 16, size.y - 4)
      ..lineTo(cx + 6, size.y - 12)
      ..lineTo(cx - 6, size.y - 12)
      ..lineTo(cx - 16, size.y - 4)
      ..close();

    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
        ).createShader(Rect.fromLTWH(0, 0, size.x, size.y)),
    );

    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFE0F7FA),
    );

    // Cockpit
    canvas.drawCircle(
      Offset(cx, cy - 4),
      4,
      Paint()..color = const Color(0xFFFFFFFF),
    );

    if (hasShield) {
      canvas.drawCircle(
        Offset(cx, cy),
        26,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xAA00E5FF),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        26,
        Paint()
          ..color = const Color(0x2200E5FF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    if (burstMode || multiShot) {
      final accent = burstMode
          ? const Color(0xFFFFAB00)
          : const Color(0xFFE040FB);
      canvas.drawCircle(
        Offset(cx, cy + 18),
        3,
        Paint()..color = accent,
      );
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (_invuln > 0) return;

    if (other is Enemy) {
      other.removeFromParent();
      game.onPlayerHit();
    } else if (other is EnemyBullet) {
      other.removeFromParent();
      game.onPlayerHit();
    } else if (other is PowerUp) {
      game.collectPowerUp(other.type);
      other.removeFromParent();
    }
  }
}
