import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/game_audio.dart';
import '../config/play_mode.dart';
import '../audio/music_director.dart';
import '../ui/game_over_overlay.dart';
import '../ui/hud_overlay.dart';
import 'components/bullet.dart';
import 'components/enemy.dart';
import 'components/enemy_bullet.dart';
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
    this.shieldFill = 0,
    this.ammoFill = 0,
    this.ammo = 0,
    this.ammoMax = PlayerShip.ammoMax,
    this.slowWaveActive = false,
    this.destroyWaveActive = false,
  });

  final int score;
  final int lives;
  final int maxLives;
  final int combo;
  final int multiplier;
  final int highScore;
  final double shieldFill;
  final double ammoFill;
  final int ammo;
  final int ammoMax;
  final bool slowWaveActive;
  final bool destroyWaveActive;

  GameHudState copyWith({
    int? score,
    int? lives,
    int? maxLives,
    int? combo,
    int? multiplier,
    int? highScore,
    double? shieldFill,
    double? ammoFill,
    int? ammo,
    int? ammoMax,
    bool? slowWaveActive,
    bool? destroyWaveActive,
  }) {
    return GameHudState(
      score: score ?? this.score,
      lives: lives ?? this.lives,
      maxLives: maxLives ?? this.maxLives,
      combo: combo ?? this.combo,
      multiplier: multiplier ?? this.multiplier,
      highScore: highScore ?? this.highScore,
      shieldFill: shieldFill ?? this.shieldFill,
      ammoFill: ammoFill ?? this.ammoFill,
      ammo: ammo ?? this.ammo,
      ammoMax: ammoMax ?? this.ammoMax,
      slowWaveActive: slowWaveActive ?? this.slowWaveActive,
      destroyWaveActive: destroyWaveActive ?? this.destroyWaveActive,
    );
  }
}

class NavesGame extends FlameGame
    with
        HasCollisionDetection,
        MultiTouchDragDetector,
        TapCallbacks,
        KeyboardEvents {
  /// Lado corto / largo del playfield fijo (cámara Flame).
  static const double shortSide = 400;
  static const double longSide = 720;

  /// Compat: dimensiones del modo retrato (Parado).
  static const double worldWidth = shortSide;
  static const double worldHeight = longSide;

  /// Hard caps to keep FPS stable across section transitions / long sessions.
  static const int maxPlayerBullets = 48;
  static const int maxEnemyBullets = 64;
  static const int maxExplosions = 10;
  static const int maxEnemies = 36;
  static const int maxPowerUps = 8;

  // --- Feel numbers (mechanic A / B) — Bruster v1.0.5 ---
  /// Slow-wave radius around the ship (world units). Only affects enemy ships.
  static const double slowWaveRadius = 120;

  /// Base speed multiplier for enemy ships inside the slow wave (N).
  /// Feel: 0.32 → ~68% más lento (balas NO afectadas).
  static const double slowFactor = 0.32;

  /// Drastic slow for fast / high-level enemies that enter the N wave.
  /// Feel: 0.08 → ~92% más lento (mucho más fuerte que 0.32) para poder esquivar.
  static const double slowFactorFast = 0.08;

  /// Enemies with speed ≥ this (or scout/zig) get [slowFactorFast] inside the wave.
  /// Feel: scouts/zig mid-late y cualquier nave ≥150 u/s.
  static const double fastEnemySpeedThreshold = 150;

  /// Passive shield regen per second while enemies are on screen and wave off.
  /// Feel: 0.4/s of 10 max → ~25s empty→full (~4%/s).
  static const double shieldPassiveRegen = 0.4;

  /// Passive ammo regen per second while enemies are on screen and destroy-wave off.
  /// Feel: 10/s of 100 max → ~10s empty→full (~10%/s) — clearly faster than shield.
  static const double ammoPassiveRegen = 10;

  /// Destructive wave radius (world units). Only removes enemy bullets (not ships).
  static const double destroyWaveRadius = 100;

  /// Ammo drained per second while holding the destructive wave (~5s at full).
  static const double destroyWaveAmmoPerSec = 20;

  NavesGame({
    this.onRequestRestart,
    this.playMode = PlayMode.parado,
  }) : super(
          camera: CameraComponent.withFixedResolution(
            width: playMode.isLandscape ? longSide : shortSide,
            height: playMode.isLandscape ? shortSide : longSide,
          ),
        );

  /// When set, Reiniciar tears down this Flame session and creates a fresh one.
  final VoidCallback? onRequestRestart;

  /// Eje de juego elegido (Parado / Acostado).
  final PlayMode playMode;

  bool get isLandscape => playMode.isLandscape;

  double get fieldWidth => isLandscape ? longSide : shortSide;
  double get fieldHeight => isLandscape ? shortSide : longSide;

  Vector2 get playArea => Vector2(fieldWidth, fieldHeight);

  /// Dirección en que avanzan los enemigos (y balas hostiles base).
  Vector2 get enemyTravelDir =>
      isLandscape ? Vector2(-1, 0) : Vector2(0, 1);

  /// Dirección de las balas del jugador.
  Vector2 get playerFireDir =>
      isLandscape ? Vector2(1, 0) : Vector2(0, -1);

  /// Eje transversal (zig / abanico).
  Vector2 get crossDir =>
      isLandscape ? Vector2(0, 1) : Vector2(1, 0);

  /// Posición inicial / respawn del jugador.
  Vector2 playerHome({double depth = 0.22}) {
    if (isLandscape) {
      return Vector2(fieldWidth * depth, fieldHeight * 0.5);
    }
    // depth 0.22 → y≈0.78; depth 0.18 → y≈0.82 (respawn).
    return Vector2(fieldWidth * 0.5, fieldHeight * (1.0 - depth));
  }

  final hud = ValueNotifier(const GameHudState());
  final _rng = Random();

  late PlayerShip player;
  late VirtualJoystick joystick;
  late SpawnManager spawnManager;
  late Starfield starfield;
  final musicDirector = MusicDirector.instance;

  bool isPaused = false;
  bool isGameOver = false;
  bool _shooting = false;
  bool _keyboardShooting = false;
  bool _detached = false;

  /// Hold inputs for mechanic A (N / mobile shield button).
  bool _shieldHoldKey = false;
  bool _shieldHoldTouch = false;

  /// Hold inputs for mechanic B (M / mobile destroy button).
  bool _destroyHoldKey = false;
  bool _destroyHoldTouch = false;

  bool slowWaveActive = false;
  bool destroyWaveActive = false;

  /// Last ability requested (N vs M) for mutual exclusion.
  /// 0 = none, 1 = slow (N), 2 = destroy (M).
  int _lastAbility = 0;

  /// Bumps on restart / detach to cancel in-flight section-boundary Futures.
  int _sectionEpoch = 0;

  /// Called by [GamePage] to restore Focus for web keyboard input.
  VoidCallback? requestKeyboardFocus;
  double _fireCooldown = 0;
  double _shakeTime = 0;
  double _shakeMag = 0;
  Vector2 _cameraRest = Vector2.zero();
  double _noChargeCooldown = 0;
  double _destroySfxCooldown = 0;
  double _shieldSfxCooldown = 0;

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
    if (_detached) return;

    camera.viewfinder.anchor = Anchor.topLeft;
    _cameraRest = Vector2.zero();

    await musicDirector.ensureLoaded();
    musicDirector.beginAct(GameAudio.instance.trackIndex);
    GameAudio.instance.onSectionBoundary = _onSectionBoundary;

    starfield = Starfield();
    world.add(starfield);

    player = PlayerShip();
    world.add(player);
    _playerReady = true;

    joystick = VirtualJoystick();
    camera.viewport.add(joystick);

    spawnManager = SpawnManager();
    world.add(spawnManager);

    await _loadHighScore();
    _publishHud();
  }

  /// Clear audio hooks and cancel pending section work (safe to call twice).
  void prepareTeardown() {
    _detached = true;
    _sectionEpoch++;
    isGameOver = true;
    isPaused = true;
    _cancelWaves();
    if (GameAudio.instance.onSectionBoundary == _onSectionBoundary) {
      GameAudio.instance.onSectionBoundary = null;
    }
    requestKeyboardFocus = null;
    try {
      pauseEngine();
    } catch (_) {}
  }

  /// Drop remaining Flame children after the GameWidget has swapped sessions.
  void destroySession() {
    prepareTeardown();
    try {
      overlays.clear();
    } catch (_) {}
    try {
      world.removeAll(world.children.toList());
    } catch (_) {}
    try {
      camera.viewport.removeAll(camera.viewport.children.toList());
    } catch (_) {}
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
    if (_detached) return;
    final mult = _comboMultiplier();
    final ready = _playerReady && player.isMounted;
    hud.value = GameHudState(
      score: _score,
      lives: _lives,
      combo: _combo,
      multiplier: mult,
      highScore: max(_highScore, _score),
      shieldFill: ready ? player.shieldFill : 0,
      ammoFill: ready ? player.ammoFill : 0,
      ammo: ready ? player.ammo : 0,
      ammoMax: PlayerShip.ammoMax,
      slowWaveActive: slowWaveActive,
      destroyWaveActive: destroyWaveActive,
    );
  }

  int _comboMultiplier() {
    if (_combo >= 20) return 5;
    if (_combo >= 12) return 4;
    if (_combo >= 7) return 3;
    if (_combo >= 3) return 2;
    return 1;
  }

  /// Time scale for an enemy ship under mechanic A (N shield wave).
  /// Only slows enemy ships — never bullets. Fast/high-level → drastic factor.
  double enemyTimeScale(Enemy enemy) {
    if (!slowWaveActive || !_playerReady || !player.isMounted) return 1;
    if (enemy.position.distanceTo(player.position) > slowWaveRadius) return 1;
    final fast = enemy.speed >= fastEnemySpeedThreshold ||
        enemy.kind == EnemyKind.scout ||
        enemy.kind == EnemyKind.zig;
    return fast ? slowFactorFast : slowFactor;
  }

  /// Deprecated positional helper (ships only via [enemyTimeScale]).
  double entityTimeScaleAt(Vector2 pos) {
    if (!slowWaveActive || !_playerReady || !player.isMounted) return 1;
    if (pos.distanceTo(player.position) <= slowWaveRadius) return slowFactor;
    return 1;
  }

  /// Bullets are NOT affected by the N slow wave (Bruster v1.0.5).
  double projectileTimeScaleAt(Vector2 pos) => 1;

  void _cancelWaves() {
    slowWaveActive = false;
    destroyWaveActive = false;
    _shieldHoldKey = false;
    _shieldHoldTouch = false;
    _destroyHoldKey = false;
    _destroyHoldTouch = false;
    _lastAbility = 0;
  }

  /// Mobile / overlay: set shield hold (N). Mutually exclusive with M.
  void setShieldHold(bool holding) {
    _shieldHoldTouch = holding;
    if (holding) {
      _lastAbility = 1;
      // Cancel destroy wave / holds — cannot use N and M together.
      _destroyHoldTouch = false;
      _destroyHoldKey = false;
      destroyWaveActive = false;
      _tryStartSlowWave();
    } else if (!_shieldHoldKey) {
      slowWaveActive = false;
    }
  }

  /// Mobile / overlay: set destroy-wave hold (M). Mutually exclusive with N.
  void setDestroyHold(bool holding) {
    _destroyHoldTouch = holding;
    if (holding) {
      _lastAbility = 2;
      _shieldHoldTouch = false;
      _shieldHoldKey = false;
      slowWaveActive = false;
      _tryStartDestroyWave();
    } else if (!_destroyHoldKey) {
      destroyWaveActive = false;
    }
  }

  void _tryStartSlowWave() {
    if (!_playerReady || !player.isMounted) return;
    if (player.shieldCharge <= 0) {
      _softNoChargeFeedback();
      slowWaveActive = false;
      return;
    }
    // Mutual exclusion: block if destroy is the active choice.
    if ((_destroyHoldKey || _destroyHoldTouch) && _lastAbility == 2) {
      slowWaveActive = false;
      return;
    }
    destroyWaveActive = false;
    slowWaveActive = true;
  }

  void _tryStartDestroyWave() {
    if (!_playerReady || !player.isMounted) return;
    if (player.ammo <= 0) {
      _softNoChargeFeedback();
      destroyWaveActive = false;
      return;
    }
    if ((_shieldHoldKey || _shieldHoldTouch) && _lastAbility == 1) {
      destroyWaveActive = false;
      return;
    }
    slowWaveActive = false;
    destroyWaveActive = true;
  }

  void _softNoChargeFeedback() {
    if (_noChargeCooldown > 0) return;
    _noChargeCooldown = 0.35;
    unawaited(GameAudio.instance.playNoCharge());
    _hapticLight();
  }

  @override
  void update(double dt) {
    if (_detached || isPaused || isGameOver) return;
    musicDirector.update();
    starfield.scrollScale = musicDirector.cue.scrollScale;
    super.update(dt);
    _enforceEntityCaps();

    if (_noChargeCooldown > 0) _noChargeCooldown -= dt;
    if (_destroySfxCooldown > 0) _destroySfxCooldown -= dt;
    if (_shieldSfxCooldown > 0) _shieldSfxCooldown -= dt;

    _updateWaves(dt);

    if (_combo > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) {
        _combo = 0;
        _publishHud();
      }
    }

    _fireCooldown -= dt;
    if ((_shooting || _keyboardShooting) &&
        _fireCooldown <= 0 &&
        player.isMounted) {
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

    _publishHud();
  }

  void _updateWaves(double dt) {
    if (!_playerReady || !player.isMounted) {
      _cancelWaves();
      return;
    }

    var wantSlow = _shieldHoldKey || _shieldHoldTouch;
    var wantDestroy = _destroyHoldKey || _destroyHoldTouch;

    // Mutual exclusion N/M: only the last-requested ability may run.
    if (wantSlow && wantDestroy) {
      if (_lastAbility == 2) {
        wantSlow = false;
        slowWaveActive = false;
      } else {
        wantDestroy = false;
        destroyWaveActive = false;
        _lastAbility = 1;
      }
    }

    final inCombat = world.children.whereType<Enemy>().isNotEmpty;

    // --- Mechanic A: slow wave — only enemy ships (usable whenever shieldCharge > 0) ---
    if (wantSlow && player.shieldCharge > 0) {
      if (!slowWaveActive) {
        slowWaveActive = true;
        _hapticSelection();
        if (_shieldSfxCooldown <= 0) {
          unawaited(GameAudio.instance.playShieldWave());
          _shieldSfxCooldown = 0.45;
        }
      }
      player.shieldCharge = max(0.0, player.shieldCharge - dt); // 1:1 drain
      if (player.shieldCharge <= 0) {
        player.shieldCharge = 0;
        slowWaveActive = false;
      }
    } else {
      slowWaveActive = false;
      // Passive regen in combat while wave is off.
      if (inCombat && player.shieldCharge < PlayerShip.shieldChargeMax) {
        player.shieldCharge = min(
          PlayerShip.shieldChargeMax,
          player.shieldCharge + shieldPassiveRegen * dt,
        );
      }
    }

    // --- Mechanic B: destructive wave (usable whenever ammo > 0) ---
    if (wantDestroy && player.ammo > 0) {
      if (!destroyWaveActive) {
        destroyWaveActive = true;
        _hapticSelection();
        if (_destroySfxCooldown <= 0) {
          unawaited(GameAudio.instance.playDestroyWave());
          _destroySfxCooldown = 0.35;
        }
      }
      // Drain ammo faster than normal fire (~20/s → ~5s at full stock).
      final drain = destroyWaveAmmoPerSec * dt;
      _destroyAmmoAcc += drain;
      final whole = _destroyAmmoAcc.floor();
      if (whole > 0) {
        player.ammo = max(0, player.ammo - whole);
        _destroyAmmoAcc -= whole;
      }
      if (player.ammo <= 0) {
        player.ammo = 0;
        destroyWaveActive = false;
        _destroyAmmoAcc = 0;
      } else {
        _applyDestroyWave();
        if (_destroySfxCooldown <= 0) {
          unawaited(GameAudio.instance.playDestroyWave());
          _destroySfxCooldown = 0.4;
        }
      }
    } else {
      destroyWaveActive = false;
      _destroyAmmoAcc = 0;
      // Passive ammo regen in combat while destroy-wave is off (clearly > shield).
      if (inCombat && player.ammo < PlayerShip.ammoMax) {
        _ammoRegenAcc += ammoPassiveRegen * dt;
        final gain = _ammoRegenAcc.floor();
        if (gain > 0) {
          player.ammo = min(PlayerShip.ammoMax, player.ammo + gain);
          _ammoRegenAcc -= gain;
        }
      }
    }
  }

  double _destroyAmmoAcc = 0;
  double _ammoRegenAcc = 0;

  void _applyDestroyWave() {
    // Bruster: bomb (M) only removes enemy bullets — never destroys enemy ships.
    final origin = player.position;
    final eBullets = world.children.whereType<EnemyBullet>().toList();
    for (final b in eBullets) {
      if (!b.isMounted) continue;
      if (b.position.distanceTo(origin) <= destroyWaveRadius) {
        b.removeFromParent();
      }
    }
  }

  void _fire() {
    final cost = player.fireAmmoCost;
    if (player.ammo < cost) {
      _softNoChargeFeedback();
      return;
    }
    player.trySpendAmmo(cost);

    final rate = player.fireRate;
    _fireCooldown = rate;
    final origin = player.position.clone();
    final bullets = <Bullet>[];

    final fwd = playerFireDir;
    final cross = crossDir;
    final muzzle = fwd * 24;
    if (player.multiShot) {
      bullets.addAll([
        Bullet(
          position: origin + muzzle + cross * -14 + fwd * -4,
          velocity: fwd * 420 + cross * -40,
          landscape: isLandscape,
        ),
        Bullet(
          position: origin + muzzle,
          velocity: fwd * 480,
          landscape: isLandscape,
        ),
        Bullet(
          position: origin + muzzle + cross * 14 + fwd * -4,
          velocity: fwd * 420 + cross * 40,
          landscape: isLandscape,
        ),
      ]);
    } else if (player.burstMode) {
      bullets.addAll([
        Bullet(
          position: origin + muzzle + cross * -6,
          velocity: fwd * 520,
          landscape: isLandscape,
        ),
        Bullet(
          position: origin + muzzle * 0.75 + cross * 6,
          velocity: fwd * 480,
          landscape: isLandscape,
        ),
      ]);
    } else {
      bullets.add(
        Bullet(
          position: origin + muzzle,
          velocity: fwd * 480,
          landscape: isLandscape,
        ),
      );
    }

    world.addAll(bullets);
    unawaited(
      GameAudio.instance.playShoot(
        multiShot: player.multiShot,
        burstMode: player.burstMode,
      ),
    );
    _publishHud();
  }

  void onEnemyKilled(Enemy enemy) {
    _combo += 1;
    _comboTimer = 2.2;
    final points = enemy.pointValue * _comboMultiplier();
    _score += points;
    _publishHud();

    _spawnExplosion(enemy.position.clone(), enemy.neonColor);

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
    // Enemy bullet hit: shield absorbs while charge remains (dump charge, cancel N).
    if (_playerReady && player.isMounted && player.shieldCharge > 0) {
      player.shieldCharge = 0;
      slowWaveActive = false;
      player.grantBriefInvuln(0.45);
      _spawnExplosion(
        player.position.clone(),
        const Color(0xFF69F0AE),
        intensity: 0.85,
      );
      _shake(0.16, 5);
      _hapticLight();
      unawaited(GameAudio.instance.playShieldWave());
      _publishHud();
      return;
    }

    _loseLifeFromHit(downgradeWeapon: false);
  }

  /// Enemy ship ramming: always -1 life, shieldCharge=0, cancel N, downgrade weapon.
  void onPlayerShipImpact() {
    if (_playerReady && player.isMounted) {
      player.shieldCharge = 0;
      slowWaveActive = false;
      player.downgradeWeaponTier();
    }
    _loseLifeFromHit(downgradeWeapon: false); // already downgraded above
  }

  void _loseLifeFromHit({required bool downgradeWeapon}) {
    if (downgradeWeapon && _playerReady && player.isMounted) {
      player.downgradeWeaponTier();
    }
    _lives -= 1;
    _combo = 0;
    _publishHud();
    _spawnExplosion(
      player.position.clone(),
      const Color(0xFFFF4081),
      intensity: 1.1,
    );
    _shake(0.28, 8);
    _hapticLight();

    if (_lives <= 0) {
      _triggerGameOver();
    } else if (_playerReady && player.isMounted) {
      player.respawn();
    }
  }

  void _spawnExplosion(Vector2 position, Color color, {double intensity = 1}) {
    final existing = world.children.whereType<Explosion>().length;
    if (existing >= maxExplosions) {
      final explosions = world.children.whereType<Explosion>();
      if (explosions.isNotEmpty) {
        explosions.first.removeFromParent();
      }
    }
    world.add(Explosion(position: position, color: color, intensity: intensity));
  }

  Future<void> _triggerGameOver() async {
    isGameOver = true;
    _cancelWaves();
    await GameAudio.instance.pause();
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

  /// Clear player + enemy projectiles and orphan explosions.
  void _clearProjectiles({bool includeExplosions = true}) {
    final toRemove = <Component>[
      ...world.children.whereType<Bullet>(),
      ...world.children.whereType<EnemyBullet>(),
    ];
    if (includeExplosions) {
      toRemove.addAll(world.children.whereType<Explosion>());
    }
    world.removeAll(toRemove);
  }

  void _enforceEntityCaps() {
    void cull<T extends Component>(int max) {
      final list = world.children.whereType<T>().toList();
      final overflow = list.length - max;
      if (overflow <= 0) return;
      for (var i = 0; i < overflow; i++) {
        list[i].removeFromParent();
      }
    }

    cull<Bullet>(maxPlayerBullets);
    cull<EnemyBullet>(maxEnemyBullets);
    cull<Explosion>(maxExplosions);
    cull<Enemy>(maxEnemies);
    cull<PowerUp>(maxPowerUps);
  }

  /// End of a BGM track = end of section (juice + brief spawn pause), then next act.
  Future<void> _onSectionBoundary(int completedIndex, int nextIndex) async {
    if (_detached || isGameOver) return;
    final epoch = _sectionEpoch;
    musicDirector.beginSectionEnd();
    spawnManager.pausedForSection = true;

    // Cancel waves + hard-clear projectiles so nothing lingers across the act.
    _cancelWaves();
    _clearProjectiles(includeExplosions: false);

    final enemies = world.children.whereType<Enemy>().toList();
    for (var i = 0; i < enemies.length; i++) {
      if (i.isOdd) continue;
      final e = enemies[i];
      if (!e.isMounted) continue;
      _spawnExplosion(e.position.clone(), e.neonColor, intensity: 0.85);
      e.removeFromParent();
    }
    _enforceEntityCaps();
    _shake(0.35, 7);

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (_detached || isGameOver || epoch != _sectionEpoch) return;

    spawnManager.pausedForSection = false;
    musicDirector.beginAct(nextIndex);
  }

  void pauseGame() {
    isPaused = true;
    pauseEngine();
    unawaited(GameAudio.instance.pause());
  }

  void resumeGame() {
    isPaused = false;
    resumeEngine();
    unawaited(GameAudio.instance.resume());
    requestKeyboardFocus?.call();
  }

  /// Public restart entry used by overlays — prefers full session recreate.
  void restart() {
    final recreate = onRequestRestart;
    if (recreate != null) {
      // Cancel pending section work; GamePage swaps in a fresh NavesGame.
      _sectionEpoch++;
      prepareTeardown();
      recreate();
      unawaited(GameAudio.instance.resume());
      return;
    }
    _restartInPlace();
  }

  void _restartInPlace() {
    _sectionEpoch++;
    isGameOver = false;
    isPaused = false;
    _score = 0;
    _lives = 3;
    _combo = 0;
    _comboTimer = 0;
    _shooting = false;
    _keyboardShooting = false;
    _movePointer = null;
    _shootPointer = null;
    _cancelWaves();
    _destroyAmmoAcc = 0;
    _ammoRegenAcc = 0;
    if (_playerReady && player.isMounted) {
      player.keyboardDelta = Vector2.zero();
      player.joystickDelta = Vector2.zero();
      player.dragTarget = null;
    }
    _fireCooldown = 0;
    _shakeTime = 0;
    camera.viewfinder.position = _cameraRest.clone();

    world.removeAll(
      world.children.where(
        (c) =>
            c is Enemy ||
            c is Bullet ||
            c is EnemyBullet ||
            c is PowerUp ||
            c is Explosion,
      ),
    );

    if (player.isMounted) {
      player.resetState();
    }
    spawnManager.reset();
    musicDirector.beginAct(GameAudio.instance.trackIndex);
    GameAudio.instance.onSectionBoundary = _onSectionBoundary;
    overlays.remove(GameOverOverlay.id);
    overlays.remove('pause'); // PauseOverlay.id
    if (!overlays.isActive(HudOverlay.id)) {
      overlays.add(HudOverlay.id);
    }
    resumeEngine();
    unawaited(GameAudio.instance.resume());
    _publishHud();
    requestKeyboardFocus?.call();
  }

  void _shake(double duration, double magnitude) {
    _shakeTime = duration;
    _shakeMag = magnitude;
  }

  void _hapticLight() {
    if (kIsWeb) return;
    HapticFeedback.lightImpact();
  }

  void _hapticSelection() {
    if (kIsWeb) return;
    HapticFeedback.selectionClick();
  }

  void _hapticMedium() {
    if (kIsWeb) return;
    HapticFeedback.mediumImpact();
  }

  /// Stop auto-fire immediately on touch/space release.
  void _stopShooting({bool touch = false, bool keyboard = false}) {
    if (touch) _shooting = false;
    if (keyboard) _keyboardShooting = false;
    if (!touch && !keyboard) {
      _shooting = false;
      _keyboardShooting = false;
    }
  }

  static bool _isControlKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.keyD ||
        key == LogicalKeyboardKey.keyW ||
        key == LogicalKeyboardKey.keyS ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.keyN ||
        key == LogicalKeyboardKey.keyM;
  }

  void _applyKeyboard(Set<LogicalKeyboardKey> keysPressed) {
    if (!_playerReady || _detached) return;

    var x = 0.0;
    var y = 0.0;
    if (keysPressed.contains(LogicalKeyboardKey.keyA)) x -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyD)) x += 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyW)) y -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyS)) y += 1;

    final delta = Vector2(x, y);
    player.keyboardDelta =
        delta.length2 > 0 ? delta.normalized() : Vector2.zero();
    final spaceDown = keysPressed.contains(LogicalKeyboardKey.space);
    if (spaceDown) {
      _keyboardShooting = true;
    } else if (_keyboardShooting) {
      // Release space → stop shooting immediately (no trailing shot).
      _stopShooting(keyboard: true);
    }

    final nDown = keysPressed.contains(LogicalKeyboardKey.keyN);
    final mDown = keysPressed.contains(LogicalKeyboardKey.keyM);
    if (nDown && !_shieldHoldKey) {
      _lastAbility = 1;
      _shieldHoldKey = true;
      // Mutual exclusion: cancel M when N is pressed.
      _destroyHoldKey = false;
      _destroyHoldTouch = false;
      destroyWaveActive = false;
      _tryStartSlowWave();
    } else if (!nDown) {
      _shieldHoldKey = false;
      if (!_shieldHoldTouch) slowWaveActive = false;
    }
    if (mDown && !_destroyHoldKey) {
      _lastAbility = 2;
      _destroyHoldKey = true;
      _shieldHoldKey = false;
      _shieldHoldTouch = false;
      slowWaveActive = false;
      _tryStartDestroyWave();
    } else if (!mDown) {
      _destroyHoldKey = false;
      if (!_destroyHoldTouch) destroyWaveActive = false;
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _applyKeyboard(keysPressed);
    if (_isControlKey(event.logicalKey)) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  int? _movePointer;
  int? _shootPointer;

  @override
  void onDragStart(int pointerId, DragStartInfo info) {
    final screen = info.eventPosition.widget;
    final size = canvasSize;
    final moveFrac = isLandscape ? 0.42 : 0.55;
    if (screen.x < size.x * moveFrac) {
      _movePointer = pointerId;
      joystick.onTouchStart(screen);
      player.dragTarget = _screenToWorld(screen);
    } else {
      // Right side still shoots; ability buttons live in Flutter HUD overlay
      // and consume their own pointers before Flame sees them.
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
      _stopShooting(touch: true);
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
      _stopShooting(touch: true);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final screen = event.canvasPosition;
    final moveFrac = isLandscape ? 0.42 : 0.55;
    if (screen.x >= canvasSize.x * moveFrac) {
      _shooting = true;
    } else {
      player.dragTarget = _screenToWorld(screen);
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    _stopShooting(touch: true);
    player.dragTarget = null;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _stopShooting(touch: true);
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
