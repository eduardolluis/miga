import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:miga/features/groceries/data/supermarket_price_source.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';

Map<String, dynamic> national({
  String currency = 'DOP',
  String host = 'supermercadosnacional.com',
  String stock = 'IN_STOCK',
}) => {
  'data': {
    'storeConfig': {'base_url': 'https://$host/'},
    'products': {
      'items': [
        {
          '__typename': 'SimpleProduct',
          'sku': 'sku-1',
          'name': 'Arroz Líder 10 Lb',
          'url_key': 'arroz-lider',
          'stock_status': stock,
          'price_range': {
            'minimum_price': {
              'final_price': {'value': 339.95, 'currency': currency},
            },
          },
        },
      ],
    },
  },
};

List<Map<String, dynamic>> sirena({
  num amount = 169,
  num stock = 10,
  String seller = '1',
}) => [
  {
    'productName': 'Arroz Wala 5 Lb',
    'link': 'https://nuevo.sirena.do/arroz-wala/p',
    'items': [
      {
        'itemId': 'sku-2',
        'measurementUnit': 'un',
        'unitMultiplier': 1,
        'name': '1 Und.',
        'ean': '12345',
        'sellers': [
          {
            'sellerId': seller,
            'commertialOffer': {'Price': amount, 'AvailableQuantity': stock},
          },
        ],
      },
    ],
  },
];

void main() {
  test('Reads independent store offers with SKU, package, source and query timestamp', () async {
    final now = DateTime.utc(2026, 10, 30, 22);
    var requests = 0;
    final source = SupermarketPriceSource(
      now: () => now,
      client: MockClient((request) async {
        requests++;
        if (request.url.host == 'supermercadosnacional.com') {
          expect(
            jsonDecode(request.url.queryParameters['variables']!)['term'],
            'arroz',
          );
          return http.Response(
            jsonEncode(national()),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        expect(request.url.pathSegments.last, 'arroz');
        return http.Response(jsonEncode(sirena()), 206);
      }),
    );
    final results = await source.search('arroz');
    expect(requests, 2);
    expect(results[0].offers.single.priceCents, 33995);
    expect(results[0].offers.single.sku, 'sku-1');
    expect(results[1].offers.single.priceCents, 16900);
    expect(results[1].offers.single.ean, '12345');
    expect(results[1].offers.single.observedAt, now);
    expect(results[2].store, Supermarket.jumbo);
    expect(results[2].unavailable, isTrue);
    expect(results[2].offers, isEmpty);
  });

  test('Never rebrands another store response as Nacional; other stores still work', () async {
    final source = SupermarketPriceSource(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode(
            request.url.host == 'supermercadosnacional.com'
                ? national(host: 'other.example')
                : sirena(),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    final results = await source.search('rice');
    expect(results.first.unavailable, isTrue);
    expect(results.first.offers, isEmpty);
    expect(results[1].offers, hasLength(1));
  });

  test('Unpriced, out-of-stock, foreign-currency and third-party offers are excluded', () async {
    final source = SupermarketPriceSource(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode(
            request.url.host == 'supermercadosnacional.com'
                ? national(currency: 'USD')
                : sirena(amount: 0),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    final results = await source.search('rice');
    expect(results.expand((r) => r.offers), isEmpty);
    final unavailable = SupermarketPriceSource(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode(
            request.url.host == 'supermercadosnacional.com'
                ? national(stock: 'OUT_OF_STOCK')
                : sirena(seller: 'other', stock: 0),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    expect((await unavailable.search('rice')).expand((r) => r.offers), isEmpty);
  });

  test(
    'Failed store requests never become zero-priced or historical live offers',
    () async {
      final source = SupermarketPriceSource(
        client: MockClient((_) async => http.Response('unavailable', 503)),
      );
      final results = await source.search('rice');
      expect(results.every((r) => r.unavailable && r.offers.isEmpty), isTrue);
    },
  );
}
