import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../config/play_mode.dart';
import '../game/naves_game.dart';
import 'game_over_overlay.dart';
import 'hud_overlay.dart';
import 'pause_overlay.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key, this.playMode = PlayMode.parado});

  final PlayMode playMode;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late NavesGame _game;
  late PlayMode _playMode;
  late final FocusNode _gameFocus;
  int _session = 0;

  @override
  void initState() {
    super.initState();
    _playMode = widget.playMode;
    _gameFocus = FocusNode(debugLabel: 'naves-game');
    _bootGame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PlayModePrefs.applyOrientation(_playMode);
      _ensureGameFocus();
    });
  }

  void _bootGame() {
    _game = NavesGame(
      onRequestRestart: _recreateSession,
      playMode: _playMode,
    );
    _game.requestKeyboardFocus = _ensureGameFocus;
  }

  /// Full teardown + new Flame session (no stacked timers/components/listeners).
  void _recreateSession() {
    final old = _game;
    old.prepareTeardown();
    setState(() {
      _session++;
      _bootGame();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      old.destroySession();
      _ensureGameFocus();
    });
  }

  /// Cambia Parado/Acostado desde pausa: guarda, orienta y reinicia el layout.
  Future<void> applyPlayMode(PlayMode mode) async {
    if (mode == _playMode) return;
    await PlayModePrefs.save(mode);
    await PlayModePrefs.applyOrientation(mode);
    if (!mounted) return;
    setState(() => _playMode = mode);
    _recreateSession();
  }

  void _ensureGameFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_gameFocus.hasPrimaryFocus) {
        _gameFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _game.prepareTeardown();
    _game.destroySession();
    _gameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<NavesGame>(
        key: ValueKey('$_session-${_playMode.name}'),
        game: _game,
        focusNode: _gameFocus,
        autofocus: true,
        overlayBuilderMap: {
          HudOverlay.id: (context, game) => HudOverlay(game: game),
          PauseOverlay.id: (context, game) => PauseOverlay(
                game: game,
                playMode: _playMode,
                onPlayModeChanged: applyPlayMode,
              ),
          GameOverOverlay.id: (context, game) => GameOverOverlay(game: game),
        },
        initialActiveOverlays: const [HudOverlay.id],
        loadingBuilder: (context) => const ColoredBox(
          color: Color(0xFF050816),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
          ),
        ),
      ),
    );
  }
}
