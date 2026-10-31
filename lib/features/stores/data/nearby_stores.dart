import 'package:url_launcher/url_launcher.dart';

abstract final class NearbyStores {
  static Uri searchUri(
    String languageCode, {
    String? supermarket,
  }) => Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query':
        '${supermarket ?? (languageCode == 'es' ? 'supermercados' : 'grocery stores')} ${languageCode == 'es' ? 'cerca de mí' : 'near me'}',
  });

  static Future<bool> openForStore(String supermarket, String languageCode) =>
      launchUrl(
        searchUri(languageCode, supermarket: supermarket),
        mode: LaunchMode.externalApplication,
      );
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
