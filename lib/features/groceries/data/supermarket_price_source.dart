import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:miga/features/groceries/domain/supermarket_offer.dart';

class SupermarketPriceSource {
  SupermarketPriceSource({this.client, DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final http.Client? client;
  final DateTime Function() _now;

  Future<List<StoreSearchResult>> search(String query) async {
    final term = query.trim();
    if (term.length < 2 || term.length > 100) return [];
    return Future.wait(
      Supermarket.values.map((store) => _searchStore(store, term)),
    );
  }

  Future<StoreSearchResult> _searchStore(
    Supermarket store,
    String query,
  ) async {
    // Jumbo currently returns Nacional's store context. Never label it as Jumbo.
    if (store == Supermarket.jumbo) {
      return StoreSearchResult(store, unavailable: true);
    }
    final httpClient = client ?? http.Client();
    try {
      final offers = store == Supermarket.sirena
          ? await _sirena(httpClient, query)
          : await _nacional(httpClient, query);
      return StoreSearchResult(
        store,
        offers: offers.where((offer) => _matchesQuery(offer, query)).toList(),
      );
    } catch (_) {
      return StoreSearchResult(store, unavailable: true);
    } finally {
      if (client == null) httpClient.close();
    }
  }

  bool _matchesQuery(SupermarketOffer offer, String query) {
    final terms = _searchTerms(query);
    if (terms.isEmpty) return false;
    final productTerms = _searchTerms('${offer.product} ${offer.presentation}');
    return terms.every(
      (term) => productTerms.any((candidate) => _sameTerm(candidate, term)),
    );
  }

  List<String> _searchTerms(String value) => _normalize(value)
      .split(' ')
      .where(
        (term) =>
            term.length > 1 &&
            !const {
              'a',
              'an',
              'and',
              'by',
              'de',
              'del',
              'el',
              'en',
              'for',
              'la',
              'las',
              'large',
              'medium',
              'of',
              'para',
              'por',
              'small',
              'sweet',
              'the',
              'to',
              'un',
              'una',
              'y',
            }.contains(term) &&
            !RegExp(r'^\d+(?:[.,]\d+)?$').hasMatch(term),
      )
      .toList();

  bool _sameTerm(String candidate, String query) {
    final candidates = _variants(candidate);
    return _variants(query).any(
      (term) => candidates.any(
        (candidateTerm) =>
            candidateTerm == term ||
            candidateTerm.length >= 4 && candidateTerm.startsWith(term) ||
            term.length >= 4 && term.startsWith(candidateTerm),
      ),
    );
  }

  Set<String> _variants(String value) {
    final root = value.endsWith('es')
        ? value.substring(0, value.length - 2)
        : value.endsWith('s')
        ? value.substring(0, value.length - 1)
        : value;
    const equivalents = {
      'arroz': {'rice'},
      'batata': {'potato', 'potatoes', 'papa'},
      'egg': {'huevo', 'huevos'},
      'espinaca': {'spinach'},
      'huevo': {'egg', 'eggs'},
      'oil': {'aceite'},
      'oliva': {'olive'},
      'papa': {'potato', 'potatoes', 'batata'},
      'rice': {'arroz'},
      'spinach': {'espinaca'},
    };
    return {value, root, ...?equivalents[value], ...?equivalents[root]};
  }

  String _normalize(String value) {
    var normalized = value.toLowerCase();
    for (final entry in {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    }.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  Future<dynamic> _get(http.Client client, Uri uri) async {
    final response = await client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200 && response.statusCode != 206) {
      throw StateError('Store catalog unavailable');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<List<SupermarketOffer>> _nacional(
    http.Client client,
    String query,
  ) async {
    final graphql = '''query Products(\$term: String!) {
      storeConfig {base_url}
      products(search: \$term, pageSize: 12) {items {
        __typename sku name url_key stock_status
        price_range {minimum_price {final_price {value currency}}}
      }}
    }''';
    final result = await _get(
      client,
      Uri.https('supermercadosnacional.com', '/graphql', {
        'query': graphql,
        'variables': jsonEncode({'term': query}),
      }),
    ) as Map<String, dynamic>;
    if (result['errors'] != null) throw StateError('Store catalog unavailable');
    final data = result['data'] as Map<String, dynamic>;
    final base = Uri.parse(
      (data['storeConfig'] as Map<String, dynamic>)['base_url'] as String,
    );
    if (base.host != 'supermercadosnacional.com') {
      throw StateError('Wrong store context');
    }
    final items =
        (data['products'] as Map<String, dynamic>)['items'] as List<dynamic>;
    final offers = <SupermarketOffer>[];
    for (final raw in items) {
      final item = raw as Map<String, dynamic>;
      if (item['__typename'] != 'SimpleProduct' ||
          item['stock_status'] != 'IN_STOCK') {
        continue;
      }
      final price =
          item['price_range']['minimum_price']['final_price']
              as Map<String, dynamic>;
      final amount = price['value'] as num?;
      final title = item['name'] as String?;
      final sku = item['sku'] as String?;
      final slug = item['url_key'] as String?;
      if (amount == null ||
          !amount.isFinite ||
          amount <= 0 ||
          price['currency'] != 'DOP' ||
          title == null ||
          sku == null ||
          slug == null) {
        continue;
      }
      offers.add(
        SupermarketOffer(
          store: Supermarket.nacional,
          product: title,
          sku: sku,
          presentation: title,
          priceCents: (amount * 100).round(),
          sourceUrl: Uri.https(
            'supermercadosnacional.com',
            '/$slug',
          ).toString(),
          observedAt: _now(),
        ),
      );
    }
    return offers;
  }

  Future<List<SupermarketOffer>> _sirena(
    http.Client client,
    String query,
  ) async {
    final uri = Uri(
      scheme: 'https',
      host: 'nuevo.sirena.do',
      pathSegments: [
        'api',
        'catalog_system',
        'pub',
        'products',
        'search',
        query,
      ],
      queryParameters: {'_from': '0', '_to': '11'},
    );
    final products = await _get(client, uri) as List<dynamic>;
    final offers = <SupermarketOffer>[];
    for (final raw in products) {
      final product = raw as Map<String, dynamic>;
      final title = product['productName'] as String?;
      final link = product['link'] as String?;
      if (title == null || link == null) continue;
      final source = Uri.tryParse(link);
      if (source == null ||
          source.scheme != 'https' ||
          source.host != 'nuevo.sirena.do') {
        continue;
      }
      for (final rawItem in product['items'] as List<dynamic>) {
        final item = rawItem as Map<String, dynamic>;
        if (item['measurementUnit'] != 'un' || item['unitMultiplier'] != 1) {
          continue;
        }
        final sku = item['itemId'] as String?;
        if (sku == null) continue;
        for (final rawSeller in item['sellers'] as List<dynamic>) {
          final seller = rawSeller as Map<String, dynamic>;
          if (seller['sellerId'] != '1') continue;
          final price = seller['commertialOffer'] as Map<String, dynamic>;
          final amount = price['Price'] as num?;
          final available = price['AvailableQuantity'] as num?;
          if (amount == null ||
              !amount.isFinite ||
              amount <= 0 ||
              available == null ||
              available <= 0) {
            continue;
          }
          offers.add(
            SupermarketOffer(
              store: Supermarket.sirena,
              product: title,
              sku: sku,
              presentation: '$title · ${item['name'] ?? ''}',
              ean: item['ean'] as String?,
              priceCents: (amount * 100).round(),
              sourceUrl: link,
              observedAt: _now(),
            ),
          );
        }
      }
    }
    return offers;
  }
}
