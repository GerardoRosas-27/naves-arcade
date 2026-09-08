import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/game_audio.dart';
import '../config/play_mode.dart';
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
  PlayMode _playMode = PlayMode.parado;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = PlayMode.fromPrefs(prefs.getString(PlayModePrefs.key));
    if (!mounted) return;
    setState(() {
      _highScore = prefs.getInt('high_score') ?? 0;
      _playMode = mode;
    });
    await PlayModePrefs.applyOrientation(mode);
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _highScore = prefs.getInt('high_score') ?? 0);
  }

  Future<void> _selectMode(PlayMode mode) async {
    if (_playMode == mode) return;
    setState(() => _playMode = mode);
    await PlayModePrefs.save(mode);
    await PlayModePrefs.applyOrientation(mode);
    if (!mounted) return;
    HapticFeedback.selectionClick();
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
      MaterialPageRoute(
        builder: (_) => GamePage(playMode: _playMode),
      ),
    );
    // Al volver, reaplicar orientación del preferido.
    await PlayModePrefs.applyOrientation(_playMode);
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
        height: double.infinity,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final landscape = constraints.maxWidth > constraints.maxHeight;
              final pad = EdgeInsets.symmetric(
                horizontal: landscape ? 20 : 28,
                vertical: landscape ? 8 : 0,
              );
              return Padding(
                padding: pad,
                child: landscape
                    ? _buildLandscapeBody(constraints)
                    : _buildPortraitBody(),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Paisaje / Acostado: fila — branding+tips a la izquierda; controles a la derecha.
  Widget _buildLandscapeBody(BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(right: 8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _branding(compact: true),
                  const SizedBox(height: 12),
                  _tipsBox(compact: true),
                  const SizedBox(height: 10),
                  Text(
                    'Récord: $_highScore',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD54F),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 4),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _modeSection(compact: true),
                  const SizedBox(height: 14),
                  _playButton(height: 48, fontSize: 18),
                  const SizedBox(height: 10),
                  _downloadButtons(compact: true),
                  const SizedBox(height: 8),
                  _footerHints(compact: true),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Retrato / Parado: columna con scroll para pantallas bajas.
  Widget _buildPortraitBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  _branding(compact: false),
                  const Spacer(),
                  _tipsBox(compact: false),
                  const SizedBox(height: 20),
                  Text(
                    'Récord: $_highScore',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD54F),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _modeSection(compact: false),
                  const Spacer(),
                  _playButton(height: 56, fontSize: 20),
                  const SizedBox(height: 12),
                  _downloadButtons(compact: false),
                  const SizedBox(height: 10),
                  _footerHints(compact: false),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _branding({required bool compact}) {
    final iconSize = compact ? 56.0 : 88.0;
    final titleSize = compact ? 26.0 : 36.0;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        return Transform.scale(
          scale: 1 + t * 0.04,
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.rocket_launch_rounded,
            size: iconSize,
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
          SizedBox(height: compact ? 8 : 16),
          Text(
            'NAVES ARCADE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w900,
              letterSpacing: compact ? 2 : 4,
              color: const Color(0xFFE8F7FF),
              shadows: const [
                Shadow(
                  color: Color(0xFF00E5FF),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 4 : 8),
          Text(
            'Demo jugable · Flame · Multiplataforma',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              color: Colors.cyanAccent.withValues(alpha: 0.75),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipsBox({required bool compact}) {
    final gap = compact ? 4.0 : 8.0;
    final pad = compact ? 12.0 : 18.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _infoRow(
            Icons.sports_esports,
            'Arrastra o usa el joystick',
            compact: compact,
          ),
          SizedBox(height: gap),
          _infoRow(
            Icons.flash_on,
            'Mantén pulsado para disparar',
            compact: compact,
          ),
          SizedBox(height: gap),
          _infoRow(
            Icons.shield,
            compact
                ? 'N=lento · M=limpia balas'
                : 'N=lento naves · M=limpia balas · no a la vez',
            compact: compact,
          ),
          if (kIsWeb) ...[
            SizedBox(height: gap),
            _infoRow(
              Icons.keyboard,
              'Web: WASD · Espacio · N · M',
              compact: compact,
            ),
          ],
          SizedBox(height: gap),
          _infoRow(
            Icons.star,
            compact
                ? 'Armas: tier ↑↓ con power-ups / impactos'
                : 'Armas: recarga + sube tier; impacto nave baja tier',
            compact: compact,
          ),
        ],
      ),
    );
  }

  Widget _modeSection({required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Elige cómo jugar',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
              fontSize: compact ? 12 : 13,
              letterSpacing: 0.6,
            ),
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        Row(
          children: [
            Expanded(
              child: _modeCard(
                mode: PlayMode.parado,
                icon: Icons.stay_current_portrait,
                compact: compact,
              ),
            ),
            SizedBox(width: compact ? 8 : 12),
            Expanded(
              child: _modeCard(
                mode: PlayMode.acostado,
                icon: Icons.stay_current_landscape,
                compact: compact,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _playButton({required double height, required double fontSize}) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: _startGame,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF00BCD4),
          foregroundColor: const Color(0xFF050816),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          '¡JUGAR!',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _downloadButtons({required bool compact}) {
    final btnH = compact ? 40.0 : 48.0;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _outlineBtn(
                icon: Icons.android,
                label: 'APK Android',
                color: const Color(0xFFA5D6A7),
                border: const Color(0xFF66BB6A),
                onPressed: _downloadAndroidApk,
                height: btnH,
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
                height: btnH,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 6 : 8),
        SizedBox(
          width: double.infinity,
          height: compact ? 40 : 44,
          child: OutlinedButton.icon(
            onPressed: _downloadIosZip,
            icon: Icon(Icons.apple, size: compact ? 18 : 20),
            label: Text(
              'ZIP iOS (instrucciones)',
              style: TextStyle(
                fontSize: compact ? 12 : 13,
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
      ],
    );
  }

  Widget _footerHints({required bool compact}) {
    return Column(
      children: [
        Text(
          'Si se pausa: abre el link en Chrome → Descargas → '
          'permitir instalar apps desconocidas',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            height: 1.35,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
        SizedBox(height: compact ? 6 : 12),
        Text(
          'Destruye naves enemigas · Evita colisiones',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  Widget _modeCard({
    required PlayMode mode,
    required IconData icon,
    required bool compact,
  }) {
    final selected = _playMode == mode;
    return Material(
      color: selected
          ? const Color(0xFF00BCD4)
          : Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _selectMode(mode),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 10 : 14,
            horizontal: compact ? 8 : 10,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: compact ? 24 : 28,
                color: selected
                    ? const Color(0xFF050816)
                    : const Color(0xFF00E5FF),
              ),
              SizedBox(height: compact ? 6 : 8),
              Text(
                mode.label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 14 : 15,
                  color: selected
                      ? const Color(0xFF050816)
                      : const Color(0xFFE8F7FF),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                compact
                    ? (mode == PlayMode.parado ? 'Vertical' : 'Horizontal')
                    : mode.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 10 : 10,
                  height: 1.25,
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

  Widget _outlineBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color border,
    required VoidCallback onPressed,
    double height = 48,
  }) {
    return SizedBox(
      height: height,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: height < 44 ? 18 : 20),
        label: Text(
          label,
          style: TextStyle(
            fontSize: height < 44 ? 11 : 12,
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

  Widget _infoRow(IconData icon, String text, {bool compact = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: compact ? 16 : 20,
          color: const Color(0xFF00E5FF),
        ),
        SizedBox(width: compact ? 8 : 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: compact ? 12 : 14,
            ),
          ),
        ),
      ],
    );
  }
}
