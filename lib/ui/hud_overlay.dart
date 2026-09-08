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
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ValueListenableBuilder<GameHudState>(
              valueListenable: game.hud,
              builder: (context, state, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
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
                                    Shadow(
                                      color: Color(0xFF00E5FF),
                                      blurRadius: 8,
                                    ),
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
                    ),
                    const SizedBox(height: 8),
                    _ResourceBars(state: state),
                  ],
                );
              },
            ),
          ),
          // Mobile hold buttons (right side) — fill matches charge/ammo.
          // Right-edge ability holds — raised so thumbs clear the fire zone.
          Positioned(
            right: 12,
            bottom: 112,
            child: ValueListenableBuilder<GameHudState>(
              valueListenable: game.hud,
              builder: (context, state, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HoldAbilityButton(
                      label: 'N',
                      hint: 'Escudo',
                      fill: state.shieldFill,
                      active: state.slowWaveActive,
                      color: const Color(0xFF00E5FF),
                      onHoldChanged: game.setShieldHold,
                    ),
                    const SizedBox(height: 14),
                    _HoldAbilityButton(
                      label: 'M',
                      hint: 'Onda',
                      fill: state.ammoFill,
                      active: state.destroyWaveActive,
                      color: const Color(0xFFFF6D00),
                      onHoldChanged: game.setDestroyHold,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceBars extends StatelessWidget {
  const _ResourceBars({required this.state});

  final GameHudState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Bar(
            label: 'ESCUDO',
            fill: state.shieldFill,
            color: const Color(0xFF00E5FF),
            active: state.slowWaveActive,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Bar(
            label: 'MUNICIÓN ${state.ammo}',
            fill: state.ammoFill,
            color: const Color(0xFFFFAB00),
            active: state.destroyWaveActive,
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.fill,
    required this.color,
    required this.active,
  });

  final String label;
  final double fill;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: active ? color : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fill.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.white12,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _HoldAbilityButton extends StatelessWidget {
  const _HoldAbilityButton({
    required this.label,
    required this.hint,
    required this.fill,
    required this.active,
    required this.color,
    required this.onHoldChanged,
  });

  final String label;
  final String hint;
  final double fill;
  final bool active;
  final Color color;
  final ValueChanged<bool> onHoldChanged;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onHoldChanged(true),
      onPointerUp: (_) => onHoldChanged(false),
      onPointerCancel: (_) => onHoldChanged(false),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                value: fill.clamp(0.0, 1.0),
                strokeWidth: 5,
                backgroundColor: Colors.white12,
                color: color,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? color.withValues(alpha: 0.45)
                    : color.withValues(alpha: 0.18),
                border: Border.all(
                  color: active ? color : color.withValues(alpha: 0.7),
                  width: 2,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.55),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    hint,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
