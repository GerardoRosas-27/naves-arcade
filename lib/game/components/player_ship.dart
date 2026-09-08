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

  /// Feel: max 10s of slow-wave hold time.
  static const double shieldChargeMax = 10.0;

  /// Feel: ammo stock cap.
  static const int ammoMax = 100;

  /// Feel: starting ammo so the first seconds are playable.
  static const int ammoStart = 50;

  /// Feel: shield pickup grant (seconds of charge).
  static const double shieldPickupGrant = 3.5;

  /// Feel: weapon pickup ammo grants.
  static const int burstAmmoGrant = 35;
  static const int multiAmmoGrant = 40;

  Vector2 joystickDelta = Vector2.zero();
  Vector2 keyboardDelta = Vector2.zero();
  Vector2? dragTarget;

  /// Cumulative slow-wave charge (seconds of hold remaining).
  double shieldCharge = 0;

  /// Finite ammo stock.
  int ammo = ammoStart;

  bool burstMode = false;
  bool multiShot = false;

  double _invuln = 0;
  double _blink = 0;
  double _wavePulse = 0;

  double get fireRate {
    if (burstMode) return 0.09;
    if (multiShot) return 0.16;
    return 0.18;
  }

  /// Ammo spent per fire action (multi spends most).
  int get fireAmmoCost {
    if (multiShot) return 3;
    if (burstMode) return 2;
    return 1;
  }

  double get shieldFill => (shieldCharge / shieldChargeMax).clamp(0.0, 1.0);
  double get ammoFill => (ammo / ammoMax).clamp(0.0, 1.0);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(game.playArea.x / 2, game.playArea.y * 0.78);
    add(CircleHitbox(radius: 14, isSolid: true));
  }

  void resetState() {
    position = Vector2(game.playArea.x / 2, game.playArea.y * 0.78);
    shieldCharge = 0;
    ammo = ammoStart;
    burstMode = false;
    multiShot = false;
    _invuln = 1.5;
    joystickDelta = Vector2.zero();
    keyboardDelta = Vector2.zero();
    dragTarget = null;
  }

  void respawn() {
    position = Vector2(game.playArea.x / 2, game.playArea.y * 0.82);
    _invuln = 2.0;
  }

  void addShieldCharge([double amount = shieldPickupGrant]) {
    shieldCharge = min(shieldChargeMax, shieldCharge + amount);
  }

  void addAmmo(int amount) {
    ammo = min(ammoMax, ammo + amount);
  }

  bool trySpendAmmo(int cost) {
    if (ammo < cost) return false;
    ammo -= cost;
    return true;
  }

  /// Shield pickup → cumulative charge (no one-hit bubble).
  void activateShield() {
    addShieldCharge(shieldPickupGrant);
  }

  /// Weapon pickup → add stock + set type (persistent until another weapon).
  void activateBurst() {
    burstMode = true;
    multiShot = false;
    addAmmo(burstAmmoGrant);
  }

  void activateMultiShot() {
    multiShot = true;
    burstMode = false;
    addAmmo(multiAmmoGrant);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_invuln > 0) _invuln -= dt;
    _blink += dt * 12;
    _wavePulse += dt * 6;

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

    // Slow wave ring (mechanic A)
    if (game.slowWaveActive) {
      final r = NavesGame.slowWaveRadius;
      final pulse = 1 + 0.04 * sin(_wavePulse);
      canvas.drawCircle(
        Offset(cx, cy),
        r * pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xAA00E5FF),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r * pulse,
        Paint()
          ..color = const Color(0x2200E5FF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    // Destructive wave ring (mechanic B)
    if (game.destroyWaveActive) {
      final r = NavesGame.destroyWaveRadius;
      final pulse = 1 + 0.05 * sin(_wavePulse * 1.3);
      canvas.drawCircle(
        Offset(cx, cy),
        r * pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xCCFF6D00),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r * pulse * 0.85,
        Paint()
          ..color = const Color(0x33FF6D00)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

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
