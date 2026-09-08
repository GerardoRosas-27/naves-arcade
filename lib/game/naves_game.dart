import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ui/game_over_overlay.dart';
import '../ui/hud_overlay.dart';
import 'components/bullet.dart';
import 'components/enemy.dart';
import 'components/explosion.dart';
import 'components/player_ship.dart';
import 'components/power_up.dart';
import 'components/starfield.dart';
import 'components/virtual_joystick.dart';
import 'managers/spawn_manager.dart';

class GameHudState {
  const GameHudState({
    this.score = 0,
    this.lives = 3,
    this.maxLives = 3,
    this.combo = 0,
    this.multiplier = 1,
    this.highScore = 0,
    this.hasShield = false,
  });

  final int score;
  final int lives;
  final int maxLives;
  final int combo;
  final int multiplier;
  final int highScore;
  final bool hasShield;

  GameHudState copyWith({
    int? score,
    int? lives,
    int? maxLives,
    int? combo,
    int? multiplier,
    int? highScore,
    bool? hasShield,
  }) {
    return GameHudState(
      score: score ?? this.score,
      lives: lives ?? this.lives,
      maxLives: maxLives ?? this.maxLives,
      combo: combo ?? this.combo,
      multiplier: multiplier ?? this.multiplier,
      highScore: highScore ?? this.highScore,
      hasShield: hasShield ?? this.hasShield,
    );
  }
}

class NavesGame extends FlameGame
    with HasCollisionDetection, MultiTouchDragDetector, TapCallbacks {
  static const double worldWidth = 400;
  static const double worldHeight = 720;

  NavesGame()
      : super(
          camera: CameraComponent.withFixedResolution(
            width: worldWidth,
            height: worldHeight,
          ),
        );

  Vector2 get playArea => Vector2(worldWidth, worldHeight);

  final hud = ValueNotifier(const GameHudState());
  final _rng = Random();

  late PlayerShip player;
  late VirtualJoystick joystick;
  late SpawnManager spawnManager;
  late Starfield starfield;

  bool isPaused = false;
  bool isGameOver = false;
  bool _shooting = false;
  double _fireCooldown = 0;
  double _shakeTime = 0;
  double _shakeMag = 0;
  Vector2 _cameraRest = Vector2.zero();

  int _score = 0;
  int _lives = 3;
  int _combo = 0;
  double _comboTimer = 0;
  int _highScore = 0;

  static const _highScoreKey = 'high_score';

  bool _playerReady = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.anchor = Anchor.topLeft;
    _cameraRest = Vector2.zero();

    starfield = Starfield();
    world.add(starfield);

    player = PlayerShip();
    world.add(player);
    _playerReady = true;

    joystick = VirtualJoystick();
    camera.viewport.add(joystick);

    spawnManager = SpawnManager();
    world.add(spawnManager);

    // High score after player exists: _publishHud reads player.hasShield.
    await _loadHighScore();
    _publishHud();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    _highScore = prefs.getInt(_highScoreKey) ?? 0;
    _publishHud();
  }

  Future<void> _saveHighScore() async {
    if (_score > _highScore) {
      _highScore = _score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_highScoreKey, _highScore);
    }
  }

  void _publishHud() {
    final mult = _comboMultiplier();
    hud.value = GameHudState(
      score: _score,
      lives: _lives,
      combo: _combo,
      multiplier: mult,
      highScore: max(_highScore, _score),
      hasShield: _playerReady && player.isMounted && player.hasShield,
    );
  }

  int _comboMultiplier() {
    if (_combo >= 20) return 5;
    if (_combo >= 12) return 4;
    if (_combo >= 7) return 3;
    if (_combo >= 3) return 2;
    return 1;
  }

  @override
  void update(double dt) {
    if (isPaused || isGameOver) return;
    super.update(dt);

    if (_combo > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) {
        _combo = 0;
        _publishHud();
      }
    }

    _fireCooldown -= dt;
    if (_shooting && _fireCooldown <= 0 && player.isMounted) {
      _fire();
    }

    if (_shakeTime > 0) {
      _shakeTime -= dt;
      final ox = (_rng.nextDouble() - 0.5) * 2 * _shakeMag;
      final oy = (_rng.nextDouble() - 0.5) * 2 * _shakeMag;
      camera.viewfinder.position = _cameraRest + Vector2(ox, oy);
      _shakeMag *= 0.9;
      if (_shakeTime <= 0) {
        camera.viewfinder.position = _cameraRest.clone();
      }
    }
  }

  void _fire() {
    final rate = player.fireRate;
    _fireCooldown = rate;
    final origin = player.position.clone();
    final bullets = <Bullet>[];

    if (player.multiShot) {
      bullets.addAll([
        Bullet(position: origin + Vector2(-14, -20), velocity: Vector2(-40, -420)),
        Bullet(position: origin + Vector2(0, -24), velocity: Vector2(0, -480)),
        Bullet(position: origin + Vector2(14, -20), velocity: Vector2(40, -420)),
      ]);
    } else if (player.burstMode) {
      bullets.addAll([
        Bullet(position: origin + Vector2(-6, -22), velocity: Vector2(0, -520)),
        Bullet(position: origin + Vector2(6, -18), velocity: Vector2(0, -480)),
      ]);
    } else {
      bullets.add(Bullet(position: origin + Vector2(0, -24), velocity: Vector2(0, -480)));
    }

    world.addAll(bullets);
  }

  void onEnemyKilled(Enemy enemy) {
    _combo += 1;
    _comboTimer = 2.2;
    final points = enemy.pointValue * _comboMultiplier();
    _score += points;
    _publishHud();

    world.add(
      Explosion(
        position: enemy.position.clone(),
        color: enemy.neonColor,
      ),
    );

    if (_rng.nextDouble() < 0.18) {
      world.add(
        PowerUp.random(
          position: enemy.position.clone(),
          rng: _rng,
        ),
      );
    }

    _shake(0.12, 3);
    _hapticLight();
  }

  void onPlayerHit() {
    if (player.hasShield) {
      player.breakShield();
      world.add(
        Explosion(
          position: player.position.clone(),
          color: const Color(0xFF00E5FF),
          intensity: 0.6,
        ),
      );
      _shake(0.15, 4);
      _publishHud();
      _hapticMedium();
      return;
    }

    _lives -= 1;
    _combo = 0;
    _publishHud();
    world.add(
      Explosion(
        position: player.position.clone(),
        color: const Color(0xFFFF4081),
        intensity: 1.1,
      ),
    );
    _shake(0.28, 8);
    _hapticHeavy();

    if (_lives <= 0) {
      _triggerGameOver();
    } else {
      player.respawn();
    }
  }

  Future<void> _triggerGameOver() async {
    isGameOver = true;
    await _saveHighScore();
    _publishHud();
    overlays.add(GameOverOverlay.id);
  }

  void collectPowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.burst:
        player.activateBurst();
      case PowerUpType.shield:
        player.activateShield();
      case PowerUpType.multiShot:
        player.activateMultiShot();
    }
    _score += 25 * _comboMultiplier();
    _publishHud();
    _hapticMedium();
  }

  void pauseGame() {
    isPaused = true;
    pauseEngine();
  }

  void resumeGame() {
    isPaused = false;
    resumeEngine();
  }

  void restart() {
    isGameOver = false;
    isPaused = false;
    _score = 0;
    _lives = 3;
    _combo = 0;
    _comboTimer = 0;
    _shooting = false;
    _fireCooldown = 0;
    _shakeTime = 0;
    camera.viewfinder.position = _cameraRest.clone();

    world.removeAll(
      world.children.where(
        (c) => c is Enemy || c is Bullet || c is PowerUp || c is Explosion,
      ),
    );

    if (player.isMounted) {
      player.resetState();
    }
    spawnManager.reset();
    overlays.remove(GameOverOverlay.id);
    if (!overlays.isActive(HudOverlay.id)) {
      overlays.add(HudOverlay.id);
    }
    resumeEngine();
    _publishHud();
  }

  void _shake(double duration, double magnitude) {
    _shakeTime = duration;
    _shakeMag = magnitude;
  }

  void _hapticLight() {
    if (kIsWeb) return;
    HapticFeedback.lightImpact();
  }

  void _hapticMedium() {
    if (kIsWeb) return;
    HapticFeedback.mediumImpact();
  }

  void _hapticHeavy() {
    if (kIsWeb) return;
    HapticFeedback.heavyImpact();
  }

  // --- Input ---

  int? _movePointer;
  int? _shootPointer;

  @override
  void onDragStart(int pointerId, DragStartInfo info) {
    final screen = info.eventPosition.widget;
    final size = canvasSize;
    if (screen.x < size.x * 0.55) {
      _movePointer = pointerId;
      joystick.onTouchStart(screen);
      player.dragTarget = _screenToWorld(screen);
    } else {
      _shootPointer = pointerId;
      _shooting = true;
    }
  }

  @override
  void onDragUpdate(int pointerId, DragUpdateInfo info) {
    final screen = info.eventPosition.widget;
    if (pointerId == _movePointer) {
      joystick.onTouchMove(screen);
      if (joystick.hasInput) {
        player.joystickDelta = joystick.relativeDelta;
        player.dragTarget = null;
      } else {
        player.dragTarget = _screenToWorld(screen);
      }
    }
  }

  @override
  void onDragEnd(int pointerId, DragEndInfo info) {
    if (pointerId == _movePointer) {
      _movePointer = null;
      joystick.onTouchEnd();
      player.joystickDelta = Vector2.zero();
      player.dragTarget = null;
    }
    if (pointerId == _shootPointer) {
      _shootPointer = null;
      _shooting = false;
    }
  }

  @override
  void onDragCancel(int pointerId) {
    if (pointerId == _movePointer) {
      _movePointer = null;
      joystick.onTouchEnd();
      player.joystickDelta = Vector2.zero();
      player.dragTarget = null;
    }
    if (pointerId == _shootPointer) {
      _shootPointer = null;
      _shooting = false;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final screen = event.canvasPosition;
    if (screen.x >= canvasSize.x * 0.55) {
      _shooting = true;
    } else {
      player.dragTarget = _screenToWorld(screen);
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    _shooting = false;
    player.dragTarget = null;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _shooting = false;
    player.dragTarget = null;
  }

  Vector2 _screenToWorld(Vector2 screen) {
    final view = camera.visibleWorldRect;
    final sx = screen.x / canvasSize.x;
    final sy = screen.y / canvasSize.y;
    return Vector2(
      view.left + sx * view.width,
      view.top + sy * view.height,
    );
  }
}
