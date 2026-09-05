import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/naves_game.dart';

class PauseOverlay extends StatelessWidget {
  static const id = 'pause';

  const PauseOverlay({super.key, required this.game});

  final NavesGame game;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1A3A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x5500E5FF), blurRadius: 24),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PAUSA',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE8F7FF),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 24),
              _btn('Continuar', () {
                HapticFeedback.selectionClick();
                game.overlays.remove(id);
                game.resumeGame();
              }),
              const SizedBox(height: 12),
              _btn('Reiniciar', () {
                HapticFeedback.mediumImpact();
                game.overlays.remove(id);
                game.restart();
              }, outlined: true),
              const SizedBox(height: 12),
              _btn('Salir', () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              }, outlined: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(String label, VoidCallback onPressed, {bool outlined = false}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00E5FF),
                side: const BorderSide(color: Color(0xFF00E5FF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: const Color(0xFF050816),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
    );
  }
}
