import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/naves_game.dart';

class GameOverOverlay extends StatelessWidget {
  static const id = 'gameOver';

  const GameOverOverlay({super.key, required this.game});

  final NavesGame game;

  @override
  Widget build(BuildContext context) {
    final state = game.hud.value;
    final isNewRecord = state.score >= state.highScore && state.score > 0;

    return ColoredBox(
      color: Colors.black87,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0A2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isNewRecord
                      ? const Color(0xFFFFD54F)
                      : const Color(0xFFFF4081),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isNewRecord ? '¡NUEVO RÉCORD!' : 'GAME OVER',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: isNewRecord
                          ? const Color(0xFFFFD54F)
                          : const Color(0xFFFF4081),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${state.score}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE8F7FF),
                    ),
                  ),
                  Text(
                    'Récord: ${state.highScore}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        game.overlays.remove(id);
                        game.restart();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: const Color(0xFF050816),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Reiniciar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00E5FF),
                        side: const BorderSide(color: Color(0xFF00E5FF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Menú principal',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
