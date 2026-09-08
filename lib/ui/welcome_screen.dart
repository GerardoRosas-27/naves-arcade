import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/game_audio.dart';
import '../config/browser_download.dart';
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
    await GameAudio.instance.startPlaylist();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GamePage()),
    );
    await GameAudio.instance.stop();
    if (mounted) await _loadHighScore();
  }

  Future<void> _download(String url, String filename, {String? failHint}) async {
    final ok = await triggerBrowserDownload(url, filename);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failHint ??
                'No se pudo abrir la descarga. Revisa Releases en GitHub.',
          ),
        ),
      );
    }
  }

  Future<void> _downloadAndroidApk() => _download(
        DownloadUrls.androidApkUrl,
        'naves-arcade.apk',
      );

  Future<void> _downloadAndroidZip() => _download(
        DownloadUrls.androidZipUrl,
        'naves-arcade-android.zip',
      );

  Future<void> _downloadIosZip() async {
    // No signed IPA — ZIP is instructions only; still offer download + dialog.
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1A3A),
        title: const Text(
          'Descarga iOS',
          style: TextStyle(color: Color(0xFFE8F7FF)),
        ),
        content: const Text(
          'Todavía no hay un IPA firmado instalable. '
          'El ZIP solo incluye instrucciones de instalación / requisitos '
          '(Mac + Xcode + firma Apple).\n\n'
          'Puedes descargar el ZIP de instrucciones o abrir Releases.',
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
              await _download(
                DownloadUrls.iosZipUrl,
                'naves-arcade-ios.zip',
              );
            },
            child: const Text('Descargar ZIP'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _download(
                DownloadUrls.releasesPageUrl,
                'releases.html',
              );
            },
            child: const Text('Ver Releases'),
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
                      child: _outlineBtn(
                        icon: Icons.android,
                        label: 'APK Android',
                        color: const Color(0xFFA5D6A7),
                        border: const Color(0xFF66BB6A),
                        onPressed: _downloadAndroidApk,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _outlineBtn(
                        icon: Icons.folder_zip,
                        label: 'ZIP Android',
                        color: const Color(0xFFA5D6A7),
                        border: const Color(0xFF66BB6A),
                        onPressed: _downloadAndroidZip,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _downloadIosZip,
                    icon: const Icon(Icons.apple, size: 20),
                    label: const Text(
                      'ZIP iOS (instrucciones)',
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
                const SizedBox(height: 10),
                Text(
                  'Si se pausa: abre el link en Chrome → Descargas → '
                  'permitir instalar apps desconocidas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 12),
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

  Widget _outlineBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color border,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: border.withValues(alpha: 0.7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
