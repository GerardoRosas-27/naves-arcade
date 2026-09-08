/// URLs de descarga de builds móviles (GitHub Releases).
/// Actualiza [androidApkUrl] tras publicar un nuevo APK.
class DownloadUrls {
  DownloadUrls._();

  /// Tag del release que contiene el APK.
  static const String releaseTag = 'v1.0.1-mobile';

  /// Página de Releases del repositorio.
  static const String releasesPageUrl =
      'https://github.com/GerardoRosas-27/naves-arcade/releases';

  /// URL directa del asset APK (Android).
  static const String androidApkUrl =
      'https://github.com/GerardoRosas-27/naves-arcade/releases/download/'
      '$releaseTag/naves-arcade.apk';

  /// README / sección de builds móviles (fallback iOS).
  static const String iosInfoUrl =
      'https://github.com/GerardoRosas-27/naves-arcade#descargas-m%C3%B3viles-android--ios';
}
