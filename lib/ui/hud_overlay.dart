import 'package:flutter/material.dart';

import '../game/naves_game.dart';
import 'pause_overlay.dart';

class HudOverlay extends StatelessWidget {
  static const id = 'hud';

  const HudOverlay({super.key, required this.game});

  final NavesGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: ValueListenableBuilder<GameHudState>(
          valueListenable: game.hud,
          builder: (context, state, _) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PUNTOS  ${state.score}',
                        style: const TextStyle(
                          color: Color(0xFFE8F7FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          shadows: [
                            Shadow(color: Color(0xFF00E5FF), blurRadius: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.combo > 1
                            ? 'COMBO x${state.combo}  ·  x${state.multiplier}'
                            : 'Récord ${state.highScore}',
                        style: TextStyle(
                          color: state.combo > 1
                              ? const Color(0xFFFFD54F)
                              : Colors.white54,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(state.maxLives, (i) {
                    final alive = i < state.lives;
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.favorite,
                        size: 22,
                        color: alive
                            ? const Color(0xFFFF4081)
                            : Colors.white24,
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    game.pauseGame();
                    game.overlays.add(PauseOverlay.id);
                  },
                  icon: const Icon(Icons.pause_circle_filled),
                  color: const Color(0xFF00E5FF),
                  iconSize: 32,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
