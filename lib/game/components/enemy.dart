import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../audio/music_director.dart';
import '../naves_game.dart';
import 'bullet.dart';
import 'enemy_bullet.dart';

enum EnemyKind { scout, tank, zig }

class Enemy extends PositionComponent
    with CollisionCallbacks, HasGameReference<NavesGame> {
  Enemy({
    required Vector2 position,
    required this.kind,
    required this.speed,
    this.firePattern = FirePattern.straight,
  }) : super(
          position: position,
          size: kind == EnemyKind.tank ? Vector2(40, 36) : Vector2(30, 28),
          anchor: Anchor.center,
          priority: 5,
        );

  final EnemyKind kind;
  final double speed;
  FirePattern firePattern;
  double _phase = Random().nextDouble() * pi * 2;
  double _fireCooldown = 0.4 + Random().nextDouble() * 0.6;
  final _rng = Random();

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
    // Mechanic A (N): only enemy ships slow inside the wave (bullets unaffected).
    final scale = game.enemyTimeScale(this);
    final sdt = dt * scale;
    _phase += sdt * 3;

    final forward = game.enemyTravelDir;
    final cross = game.crossDir;
    final speedMul = kind == EnemyKind.tank ? 0.7 : 1.0;
    position += forward * (speed * speedMul * sdt);
    if (kind == EnemyKind.zig) {
      position += cross * (sin(_phase) * 90 * sdt);
    }

    _updateFire(sdt);

    // Off-screen past the player side.
    if (game.isLandscape) {
      if (position.x < -40) removeFromParent();
    } else {
      if (position.y > game.playArea.y + 40) removeFromParent();
    }
  }

  void _updateFire(double dt) {
    if (game.isPaused || game.isGameOver) return;
    // Only shoot while on-screen-ish (before reaching deep into player zone).
    if (game.isLandscape) {
      if (position.x > game.playArea.x - 10 ||
          position.x < game.playArea.x * 0.28) {
        return;
      }
    } else {
      if (position.y < 10 || position.y > game.playArea.y * 0.72) return;
    }

    final cue = MusicDirector.instance.cue;
    firePattern = cue.firePattern;
    _fireCooldown -= dt;
    if (_fireCooldown > 0) return;

    if (cue.fireOnBeatOnly && !cue.onBeat) return;

    _fire(cue);
    // Faster fire when energy is high; slower (beat-gated) when low.
    final base = kind == EnemyKind.tank ? 1.1 : 1.45;
    _fireCooldown =
        base * (1.35 - cue.energy * 0.7) * (0.85 + _rng.nextDouble() * 0.3);
  }

  void _fire(MusicCue cue) {
    final forward = game.enemyTravelDir;
    final cross = game.crossDir;
    final origin = position + forward * (size.y * 0.35);
    final bullets = <EnemyBullet>[];
    final bulletSpeed = 160 + cue.energy * 90;

    switch (firePattern) {
      case FirePattern.straight:
        bullets.add(
          EnemyBullet(
            position: origin.clone(),
            velocity: forward * bulletSpeed,
            tint: neonColor,
          ),
        );
      case FirePattern.fan:
        final count = kind == EnemyKind.tank ? 5 : 3;
        final spread = kind == EnemyKind.tank ? 0.55 : 0.4;
        for (var i = 0; i < count; i++) {
          final t = count == 1 ? 0.0 : i / (count - 1);
          final angle = -spread / 2 + t * spread;
          // Fan around travel axis (angle 0 = forward).
          final dir = forward * cos(angle) + cross * sin(angle);
          bullets.add(
            EnemyBullet(
              position: origin.clone(),
              velocity: dir * bulletSpeed,
              tint: neonColor,
            ),
          );
        }
      case FirePattern.spiral:
        final arms = kind == EnemyKind.tank ? 3 : 2;
        final baseAngle = _phase;
        for (var i = 0; i < arms; i++) {
          final angle = baseAngle + i * (2 * pi / arms);
          final vxCross = cos(angle) * bulletSpeed * 0.55;
          final vFwd = bulletSpeed * 0.85 + sin(angle).abs() * 40;
          final spin = (i.isEven ? 1 : -1) * (2.2 + cue.energy * 2.5);
          bullets.add(
            EnemyBullet(
              position: origin.clone(),
              velocity: forward * vFwd + cross * vxCross,
              spin: spin,
              tint: neonColor,
            ),
          );
        }
    }

    game.world.addAll(bullets);
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final color = neonColor;

    canvas.save();
    canvas.translate(cx, cy);
    if (game.isLandscape) {
      // Nose toward -X (toward player on the left).
      canvas.rotate(-1.57079632679);
    }
    canvas.translate(-cx, -cy);

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
    canvas.restore();
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
