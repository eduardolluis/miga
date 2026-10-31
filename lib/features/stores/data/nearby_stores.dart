import 'package:url_launcher/url_launcher.dart';

abstract final class NearbyStores {
  static Future<bool> open(String languageCode) => launchUrl(
    Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': languageCode == 'es'
          ? 'supermercados cerca de mí'
          : 'grocery stores near me',
    }),
    mode: LaunchMode.externalApplication,
  );
}
