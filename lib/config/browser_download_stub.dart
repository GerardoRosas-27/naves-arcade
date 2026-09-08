import 'package:url_launcher/url_launcher.dart';

/// Native / non-web: open the URL externally.
Future<bool> triggerBrowserDownload(String url, String filename) async {
  final uri = Uri.parse(url);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
