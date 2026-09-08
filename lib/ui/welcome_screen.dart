import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_page.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  int _highScore = 0;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _highScore = prefs.getInt('high_score') ?? 0);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _startGame() {
    if (!kIsWeb) {
      HapticFeedback.mediumImpact();
    }
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => const GamePage()),
        )
        .then((_) => _loadHighScore());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF050816),
              Color(0xFF0A1A3A),
              Color(0xFF0D0B2E),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) {
                    final t = _pulse.value;
                    return Transform.scale(
                      scale: 1 + t * 0.04,
                      child: child,
                    );
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.rocket_launch_rounded,
                        size: 88,
                        color: Color.lerp(
                          const Color(0xFF00E5FF),
                          const Color(0xFFFF00E5),
                          _pulse.value,
                        ),
                        shadows: const [
                          Shadow(
                            color: Color(0x8800E5FF),
                            blurRadius: 28,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'NAVES ARCADE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: Color(0xFFE8F7FF),
                          shadows: [
                            Shadow(
                              color: Color(0xFF00E5FF),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Demo jugable · Flame · Multiplataforma',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.cyanAccent.withValues(alpha: 0.75),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    children: [
                      _infoRow(Icons.sports_esports, 'Arrastra o usa el joystick'),
                      const SizedBox(height: 8),
                      _infoRow(Icons.flash_on, 'Mantén pulsado para disparar'),
                      const SizedBox(height: 8),
                      _infoRow(Icons.star, 'Recoge power-ups: ráfaga, escudo, multi'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Récord: $_highScore',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD54F),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _startGame,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: const Color(0xFF050816),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '¡JUGAR!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Destruye naves enemigas · Evita colisiones',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF00E5FF)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
