import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Orientación / eje de juego elegido explícitamente por el usuario.
///
/// **Parado** = vertical (retrato): enemigos arriba→abajo.
/// **Acostado** = horizontal (paisaje): enemigos derecha→izquierda.
enum PlayMode {
  parado,
  acostado;

  bool get isLandscape => this == PlayMode.acostado;

  String get label => switch (this) {
        PlayMode.parado => 'Parado',
        PlayMode.acostado => 'Acostado',
      };

  String get subtitle => switch (this) {
        PlayMode.parado => 'Vertical · naves de arriba abajo',
        PlayMode.acostado => 'Horizontal · naves de derecha a izquierda',
      };

  String get prefsValue => name;

  static PlayMode fromPrefs(String? raw) {
    if (raw == PlayMode.acostado.prefsValue) return PlayMode.acostado;
    return PlayMode.parado;
  }
}

class PlayModePrefs {
  PlayModePrefs._();

  static const key = 'play_mode';

  static Future<PlayMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PlayMode.fromPrefs(prefs.getString(key));
  }

  static Future<void> save(PlayMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, mode.prefsValue);
  }

  /// Bloquea / sugiere la orientación del dispositivo al modo elegido.
  static Future<void> applyOrientation(PlayMode mode) async {
    if (mode.isLandscape) {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  /// En menú de bienvenida permitimos ambas para rotar al elegir.
  static Future<void> unlockAllOrientations() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
}
