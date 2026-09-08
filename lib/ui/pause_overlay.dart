import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/play_mode.dart';
import '../game/naves_game.dart';

class PauseOverlay extends StatelessWidget {
  static const id = 'pause';

  const PauseOverlay({
    super.key,
    required this.game,
    required this.playMode,
    required this.onPlayModeChanged,
  });

  final NavesGame game;
  final PlayMode playMode;
  final Future<void> Function(PlayMode mode) onPlayModeChanged;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
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
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Modo de juego',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _modeChip(
                          mode: PlayMode.parado,
                          icon: Icons.stay_current_portrait,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _modeChip(
                          mode: PlayMode.acostado,
                          icon: Icons.stay_current_landscape,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cambiar el modo reinicia el layout de la partida.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
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
        ),
      ),
    );
  }

  Widget _modeChip({required PlayMode mode, required IconData icon}) {
    final selected = playMode == mode;
    return Material(
      color: selected
          ? const Color(0xFF00BCD4)
          : Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (selected) return;
          HapticFeedback.selectionClick();
          game.overlays.remove(id);
          // applyPlayMode recreates session (layout restart).
          await onPlayModeChanged(mode);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected
                    ? const Color(0xFF050816)
                    : const Color(0xFF00E5FF),
              ),
              const SizedBox(height: 6),
              Text(
                mode.label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? const Color(0xFF050816)
                      : const Color(0xFFE8F7FF),
                ),
              ),
              Text(
                mode == PlayMode.parado ? 'Vertical' : 'Horizontal',
                style: TextStyle(
                  fontSize: 11,
                  color: selected
                      ? const Color(0xFF05303A)
                      : Colors.white54,
                ),
              ),
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
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
    );
  }
}
