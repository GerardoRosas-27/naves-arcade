import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../naves_game.dart';

class VirtualJoystick extends PositionComponent
    with HasGameReference<NavesGame> {
  VirtualJoystick()
      : super(
          size: Vector2.all(120),
          position: Vector2(24, 560),
          priority: 100,
        );

  final double _knobRadius = 22;
  final double _baseRadius = 48;
  Vector2 _knob = Vector2.zero();
  bool _active = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _placeIdle();
  }

  void _placeIdle() {
    final w = game.playArea.x;
    final h = game.playArea.y;
    if (game.isLandscape) {
      // Bottom-left near player side.
      position = Vector2(16, h - size.y - 12);
    } else {
      position = Vector2(24, h - size.y - 40);
    }
    // Keep within viewport world (viewport coords ≈ play area for fixed res).
    position.x = position.x.clamp(8, w - size.x - 8);
    position.y = position.y.clamp(8, h - size.y - 8);
  }

  Vector2 get relativeDelta {
    if (!_active) return Vector2.zero();
    final max = _baseRadius - _knobRadius * 0.4;
    if (max <= 0) return Vector2.zero();
    final delta = _knob / max;
    final len = delta.length;
    if (len > 1) {
      return delta / len;
    }
    return delta;
  }

  bool get hasInput => _active && relativeDelta.length2 > 0.01;

  void onTouchStart(Vector2 screenPos) {
    _active = true;
    position = screenPos - size / 2;
    final w = game.playArea.x;
    final h = game.playArea.y;
    if (game.isLandscape) {
      position.x = position.x.clamp(8, w * 0.45 - size.x);
      position.y = position.y.clamp(8, h - size.y - 8);
    } else {
      position.x = position.x.clamp(8, w - size.x - 8);
      position.y = position.y.clamp(h * 0.55, h - size.y - 8);
    }
    _knob = Vector2.zero();
  }

  void onTouchMove(Vector2 screenPos) {
    if (!_active) return;
    final center = position + size / 2;
    var delta = screenPos - center;
    final max = _baseRadius - _knobRadius * 0.4;
    if (delta.length > max) {
      delta = delta.normalized() * max;
    }
    _knob = delta;
  }

  void onTouchEnd() {
    _active = false;
    _knob = Vector2.zero();
    _placeIdle();
  }

  @override
  void render(Canvas canvas) {
    if (!_active) {
      // Idle hint
      final c = Offset(size.x / 2, size.y / 2);
      canvas.drawCircle(
        c,
        _baseRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0x33FFFFFF),
      );
      return;
    }

    final c = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(
      c,
      _baseRadius,
      Paint()..color = const Color(0x3300E5FF),
    );
    canvas.drawCircle(
      c,
      _baseRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x8800E5FF),
    );
    canvas.drawCircle(
      Offset(c.dx + _knob.x, c.dy + _knob.y),
      _knobRadius,
      Paint()..color = const Color(0xAA00E5FF),
    );
  }
}
