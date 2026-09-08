import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/naves_game.dart';
import 'game_over_overlay.dart';
import 'hud_overlay.dart';
import 'pause_overlay.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late NavesGame _game;
  late final FocusNode _gameFocus;
  int _session = 0;

  @override
  void initState() {
    super.initState();
    _gameFocus = FocusNode(debugLabel: 'naves-game');
    _bootGame();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureGameFocus());
  }

  void _bootGame() {
    _game = NavesGame(onRequestRestart: _recreateSession);
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
        key: ValueKey(_session),
        game: _game,
        focusNode: _gameFocus,
        autofocus: true,
        overlayBuilderMap: {
          HudOverlay.id: (context, game) => HudOverlay(game: game),
          PauseOverlay.id: (context, game) => PauseOverlay(game: game),
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
