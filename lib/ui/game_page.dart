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
  late final NavesGame _game;

  @override
  void initState() {
    super.initState();
    _game = NavesGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<NavesGame>(
        game: _game,
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
