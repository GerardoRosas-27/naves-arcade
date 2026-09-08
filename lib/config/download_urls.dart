import 'package:flutter/foundation.dart';

/// URLs de descarga de builds móviles y paquetes ZIP.
/// En web: rutas same-origin servidas por Railway; en nativo: GitHub Releases.
class DownloadUrls {
  DownloadUrls._();

  /// Tag del release que contiene el APK (fallback / nativo).
  static const String releaseTag = 'v1.0.1-mobile';

  /// Página de Releases del repositorio.
  static const String releasesPageUrl =
      'https://github.com/GerardoRosas-27/naves-arcade/releases';

  /// Rutas same-origin en Railway / Express.
  static const String androidApkPath = '/downloads/naves-arcade.apk';
  static const String androidZipPath = '/downloads/naves-arcade-android.zip';
  static const String iosZipPath = '/downloads/naves-arcade-ios.zip';

  static const String _ghBase =
      'https://github.com/GerardoRosas-27/naves-arcade/releases/download/';

  static const String androidApkGithubUrl =
      '$_ghBase$releaseTag/naves-arcade.apk';
  static const String androidZipGithubUrl =
      '$_ghBase$releaseTag/naves-arcade-android.zip';
  static const String iosZipGithubUrl =
      '$_ghBase$releaseTag/naves-arcade-ios.zip';

  static String get androidApkUrl =>
      kIsWeb ? androidApkPath : androidApkGithubUrl;

  static String get androidZipUrl =>
      kIsWeb ? androidZipPath : androidZipGithubUrl;

  static String get iosZipUrl => kIsWeb ? iosZipPath : iosZipGithubUrl;

  /// README / sección de builds móviles (fallback iOS).
  static const String iosInfoUrl =
      'https://github.com/GerardoRosas-27/naves-arcade#descargas-m%C3%B3viles-android--ios';
}
