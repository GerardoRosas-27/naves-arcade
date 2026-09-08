import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../naves_game.dart';

class _Star {
  _Star(this.x, this.y, this.speed, this.size, this.alpha);

  double x;
  double y;
  double speed;
  double size;
  double alpha;
}

class Starfield extends Component with HasGameReference<NavesGame> {
  final _rng = Random();
  final _stars = <_Star>[];
  double scrollScale = 1.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final w = game.playArea.x;
    final h = game.playArea.y;
    for (var i = 0; i < 80; i++) {
      _stars.add(
        _Star(
          _rng.nextDouble() * w,
          _rng.nextDouble() * h,
          20 + _rng.nextDouble() * 90,
          0.6 + _rng.nextDouble() * 2.2,
          0.3 + _rng.nextDouble() * 0.7,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final h = game.playArea.y;
    final w = game.playArea.x;
    final landscape = game.isLandscape;
    for (final s in _stars) {
      if (landscape) {
        // Scroll toward the left (enemies come from the right).
        s.x -= s.speed * scrollScale * dt;
        if (s.x < -2) {
          s.x = w + 2;
          s.y = _rng.nextDouble() * h;
        }
      } else {
        s.y += s.speed * scrollScale * dt;
        if (s.y > h) {
          s.y = -2;
          s.x = _rng.nextDouble() * w;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.playArea.x, game.playArea.y),
      Paint()..color = const Color(0xFF050816),
    );

    // Subtle nebula
    canvas.drawCircle(
      Offset(game.playArea.x * 0.2, game.playArea.y * 0.3),
      120,
      Paint()
        ..color = const Color(0x22003D6B)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );
    canvas.drawCircle(
      Offset(game.playArea.x * 0.8, game.playArea.y * 0.6),
      100,
      Paint()
        ..color = const Color(0x221A003D)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );

    for (final s in _stars) {
      canvas.drawCircle(
        Offset(s.x, s.y),
        s.size,
        Paint()..color = Color.fromRGBO(200, 240, 255, s.alpha),
      );
    }
  }
}
