import 'browser_download_stub.dart'
    if (dart.library.html) 'browser_download_web.dart' as impl;

/// Triggers a file download (web: <a download>, native: url_launcher).
Future<bool> triggerBrowserDownload(String url, String filename) =>
    impl.triggerBrowserDownload(url, filename);
