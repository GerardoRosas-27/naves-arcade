import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../audio/game_audio.dart';
import '../config/download_urls.dart';
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

  Future<void> _startGame() async {
    if (!kIsWeb) {
      HapticFeedback.mediumImpact();
    }
    // User gesture unlocks web autoplay; start BGM playlist here.
    await GameAudio.instance.startPlaylist();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GamePage()),
    );
    await GameAudio.instance.stop();
    if (mounted) await _loadHighScore();
  }

  Future<void> _downloadAndroid() async {
    final uri = Uri.parse(DownloadUrls.androidApkUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir la descarga. Revisa Releases en GitHub.',
          ),
        ),
      );
    }
  }

  Future<void> _downloadIos() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1A3A),
        title: const Text(
          'Descarga iOS',
          style: TextStyle(color: Color(0xFFE8F7FF)),
        ),
        content: const Text(
          'iOS requiere App Store, TestFlight o un IPA firmado '
          'generado en un Mac con Xcode. Este entorno no puede '
          'producir un IPA instalable.\n\n'
          'Puedes abrir la página de Releases o el README para '
          'seguir el estado de builds móviles.',
          style: TextStyle(color: Color(0xFFB0C4DE)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final uri = Uri.parse(DownloadUrls.releasesPageUrl);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: const Text('Ver Releases'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final uri = Uri.parse(DownloadUrls.iosInfoUrl);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: const Text('Ver README'),
          ),
        ],
      ),
    );
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
                      if (kIsWeb) ...[
                        const SizedBox(height: 8),
                        _infoRow(
                          Icons.keyboard,
                          'Web: WASD mover · Espacio disparar',
                        ),
                      ],
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _downloadAndroid,
                          icon: const Icon(Icons.android, size: 20),
                          label: const Text(
                            'Descargar Android',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFA5D6A7),
                            side: BorderSide(
                              color: const Color(0xFF66BB6A).withValues(alpha: 0.7),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _downloadIos,
                          icon: const Icon(Icons.apple, size: 20),
                          label: const Text(
                            'Descargar iOS',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB0BEC5),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
