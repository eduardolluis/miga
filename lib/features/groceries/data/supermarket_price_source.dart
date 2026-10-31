import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:miga/features/groceries/domain/supermarket_offer.dart';

class SupermarketPriceSource {
  SupermarketPriceSource({
    this.client,
    DateTime Function()? now,
    this.resultLimit = 12,
  }) : _now = now ?? DateTime.now;
  final http.Client? client;
  final int resultLimit;
  final DateTime Function() _now;

  Future<List<StoreSearchResult>> search(
    String query, {
    Set<Supermarket>? stores,
  }) async {
    final term = query.trim();
    if (term.length < 2 || term.length > 100) return [];
    return Future.wait(
      (stores ?? Supermarket.values.toSet()).map(
        (store) => _searchStore(store, term),
      ),
    );
  }

  Future<StoreSearchResult> _searchStore(
    Supermarket store,
    String query,
  ) async {
    final catalogQuery = _catalogQuery(query);
    if (catalogQuery.isEmpty) return StoreSearchResult(store);
    final httpClient = client ?? http.Client();
    try {
      final offers = switch (store) {
        Supermarket.sirena => await _sirena(httpClient, catalogQuery),
        Supermarket.pricesmart => await _pricesmart(httpClient, catalogQuery),
        _ => await _magento(httpClient, catalogQuery, store),
      };
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

  String _catalogQuery(String query) => _searchTerms(query)
      .map(
        (term) =>
            const {
              'egg': 'huevo',
              'eggs': 'huevo',
              'milk': 'leche',
              'oil': 'aceite',
              'olive': 'oliva',
              'potato': 'papa',
              'potatoes': 'papa',
              'rice': 'arroz',
              'spinach': 'espinaca',
            }[term] ??
            term,
      )
      .join(' ');

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
    return _variants(query).any(candidates.contains);
  }

  Set<String> _variants(String value) {
    final roots = {
      value,
      if (value.endsWith('s')) value.substring(0, value.length - 1),
      if (value.endsWith('es')) value.substring(0, value.length - 2),
    };
    const equivalents = {
      'arroz': {'rice'},
      'egg': {'huevo', 'huevos'},
      'espinaca': {'spinach'},
      'huevo': {'egg', 'eggs'},
      'oil': {'aceite'},
      'oliva': {'olive'},
      'leche': {'milk'},
      'milk': {'leche'},
      'papa': {'potato', 'potatoes'},
      'potato': {'papa'},
      'rice': {'arroz'},
      'spinach': {'espinaca'},
    };
    return {...roots, for (final root in roots) ...?equivalents[root]};
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
    normalized = normalized.replaceAll(
      RegExp(r'\bsweet[\s-]+potato(?:es)?\b'),
      'batata',
    );
    return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  Future<dynamic> _get(
    http.Client client,
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final response = await client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200 && response.statusCode != 206) {
      throw StateError('Store catalog unavailable');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<List<SupermarketOffer>> _magento(
    http.Client client,
    String query,
    Supermarket store,
  ) async {
    final host = store == Supermarket.jumbo
        ? 'jumbo.com.do'
        : 'supermercadosnacional.com';
    final graphql =
        '''query Products(\$term: String!) {
      storeConfig {base_url}
      products(search: \$term, pageSize: ${resultLimit.clamp(1, 48)}) {items {
        __typename sku name url_key stock_status
        price_range {minimum_price {final_price {value currency}}}
      }}
    }''';
    final result = await _get(
      client,
      Uri.https(host, '/graphql', {
        'query': graphql,
        'variables': jsonEncode({'term': query}),
      }),
      headers: store == Supermarket.jumbo ? {'Store': 'jumbo'} : null,
    ) as Map<String, dynamic>;
    if (result['errors'] != null) throw StateError('Store catalog unavailable');
    final data = result['data'] as Map<String, dynamic>;
    final base = Uri.parse(
      (data['storeConfig'] as Map<String, dynamic>)['base_url'] as String,
    );
    if (base.scheme != 'https' || base.host != host) {
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
          store: store,
          product: title,
          sku: sku,
          presentation: title,
          priceCents: (amount * 100).round(),
          sourceUrl: Uri.https(host, '/$slug').toString(),
          observedAt: _now(),
        ),
      );
    }
    return offers;
  }

  Future<List<SupermarketOffer>> _pricesmart(
    http.Client client,
    String query,
  ) async {
    // Club-specific amounts are already minor units; the generic price is zero.
    const club = 'DO_6801';
    final response = await client
        .post(
          Uri.https(
            'www.pricesmart.com',
            '/api/br_discovery/getProductsByKeyword',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'q': query,
            'rows': resultLimit.clamp(1, 48),
            'start': 0,
            'view_id': 'DO',
            'domain_key': 'pricesmart_bloomreach_io_es',
            'account_id': '7024',
            'request_type': 'search',
            'search_type': 'keyword',
            'fl':
                'pid,title,currency,fractionDigits,slug,sold_by_weight_,'
                'sold_by_weight_DO,sold_by_weight_$club,'
                'price_$club,inventory_$club,availability_$club',
            'url': 'https://www.pricesmart.com/es-do/busqueda',
            'ref_url': 'https://www.pricesmart.com/es-do',
          }),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw StateError('Store catalog unavailable');
    }
    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final products = data['response']['docs'] as List<dynamic>;
    final offers = <SupermarketOffer>[];
    for (final raw in products) {
      final product = raw as Map<String, dynamic>;
      final cents = product['price_$club'] as num?;
      final title = product['title'] as String?;
      final sku = product['pid'] as String?;
      final slug = product['slug'] as String?;
      if (product['currency'] != 'DOP' ||
          product['fractionDigits'] != 2 ||
          product['inventory_$club'] != 'in stock' ||
          product['availability_$club'].toString() != 'true' ||
          product.entries.any(
            (entry) =>
                entry.key.startsWith('sold_by_weight_') &&
                entry.value.toString() == 'true',
          ) ||
          cents == null ||
          !cents.isFinite ||
          cents <= 0 ||
          cents != cents.round() ||
          title == null ||
          sku == null ||
          slug == null ||
          !RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(slug)) {
        continue;
      }
      offers.add(
        SupermarketOffer(
          store: Supermarket.pricesmart,
          product: title.trim(),
          sku: sku,
          presentation: '${title.trim()} · Los Prados (6801)',
          priceCents: cents.toInt(),
          sourceUrl: Uri.https(
            'www.pricesmart.com',
            '/es-do/producto/$slug',
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
      queryParameters: {'_from': '0', '_to': '${resultLimit.clamp(1, 48) - 1}'},
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
