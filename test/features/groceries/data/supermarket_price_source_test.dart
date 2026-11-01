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
  String name = 'Arroz Líder 10 Lb',
}) => {
  'data': {
    'storeConfig': {'base_url': 'https://$host/'},
    'products': {
      'items': [
        {
          '__typename': 'SimpleProduct',
          'sku': 'sku-1',
          'name': name,
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
  String productName = 'Arroz Wala 5 Lb',
}) => [
  {
    'productName': productName,
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
  test(
    'Sirena weighted offers preserve the actual purchasable quantity and price',
    () async {
      final product = sirena(amount: 30, productName: 'Zanahoria Fresca Lb');
      final item =
          (product.single['items'] as List).single as Map<String, dynamic>;
      item['measurementUnit'] = 'lb';
      item['unitMultiplier'] = 0.5;
      final source = SupermarketPriceSource(
        client: MockClient(
          (request) async => request.url.host == 'nuevo.sirena.do'
              ? http.Response(jsonEncode(product), 200)
              : http.Response('', 503),
        ),
      );
      final offer = (await source.search('zanahoria'))[1].offers.single;
      expect(offer.priceCents, 1500);
      expect(offer.measurementUnit, 'g');
      expect(offer.purchaseQuantity, closeTo(226.796185, 0.0001));
      final saved = SupermarketOffer.fromJson(offer.toJson());
      expect(saved.purchaseQuantity, offer.purchaseQuantity);
      expect(saved.measurementUnit, 'g');
    },
  );

  test(
    'Jumbo uses its own store header and rejects Nacional context',
    () async {
      var wrongContext = false;
      final source = SupermarketPriceSource(
        client: MockClient((request) async {
          if (request.url.host != 'jumbo.com.do') return http.Response('', 503);
          expect(request.headers['Store'], 'jumbo');
          return http.Response(
            jsonEncode(
              national(
                host: wrongContext
                    ? 'supermercadosnacional.com'
                    : 'jumbo.com.do',
              ),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final result = (await source.search('arroz'))[2];
      expect(result.offers.single.store, Supermarket.jumbo);
      expect(Uri.parse(result.offers.single.sourceUrl).host, 'jumbo.com.do');
      wrongContext = true;
      expect((await source.search('arroz'))[2].unavailable, isTrue);
    },
  );

  test(
    'PriceSmart uses DOP club cents and excludes unavailable or invalid offers',
    () async {
      final product = <String, dynamic>{
        'pid': '363516',
        'title': 'Bisono Arroz 50 lb',
        'slug': 'bisono-arroz-363516',
        'currency': 'DOP',
        'fractionDigits': 2,
        'price': 0,
        'price_DO_6801': 202000,
        'inventory_DO_6801': 'in stock',
        'availability_DO_6801': 'true',
      };
      final source = SupermarketPriceSource(
        client: MockClient((request) async {
          if (request.url.host != 'www.pricesmart.com') {
            return http.Response('', 503);
          }
          expect(request.method, 'POST');
          final body = jsonDecode(request.body);
          expect(body['view_id'], 'DO');
          expect(body['q'], 'arroz');
          return http.Response(
            jsonEncode({
              'response': {
                'docs': [
                  product,
                  {...product, 'currency': 'USD'},
                  {...product, 'inventory_DO_6801': 'out of stock'},
                  {...product, 'price_DO_6801': 0},
                  {...product, 'sold_by_weight_': true},
                  {...product, 'sold_by_weight_DO_6801': 'true'},
                  {...product, 'price_DO_6801': null},
                  {...product, 'fractionDigits': 0},
                ],
              },
            }),
            200,
          );
        }),
      );
      final result = (await source.search('rice'))[3];
      expect(result.store, Supermarket.pricesmart);
      expect(result.offers, hasLength(1));
      final offer = result.offers.single;
      expect(offer.priceCents, 202000);
      expect(offer.presentation, contains('Los Prados (6801)'));
      expect(
        SupermarketOffer.fromJson(offer.toJson()).store,
        Supermarket.pricesmart,
      );
    },
  );

  for (final example in [
    ('milk', 'leche', 'Leche entera Rica 1 L', 'Jabón corporal'),
    ('potatoes', 'papa', 'Papa blanca 1 Lb', 'Batata fresca'),
    ('papa', 'papa', 'Papas frescas', 'Papaya fresca'),
    ('tomates', 'tomates', 'Tomate fresco', 'Pasta de arroz'),
  ]) {
    test(
      'Matches ${example.$1} without conflating different ingredients',
      () async {
        final source = SupermarketPriceSource(
          client: MockClient((request) async {
            if (request.url.host == 'supermercadosnacional.com') {
              expect(
                jsonDecode(request.url.queryParameters['variables']!)['term'],
                example.$2,
              );
            } else {
              expect(request.url.pathSegments.last, example.$2);
            }
            return http.Response(
              jsonEncode(
                request.url.host == 'supermercadosnacional.com'
                    ? national(name: example.$3)
                    : sirena(productName: example.$4),
              ),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        );
        final results = await source.search(example.$1);
        expect(results.first.offers, hasLength(1));
        expect(results[1].offers, isEmpty);
      },
    );
  }
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
    expect(requests, 4);
    expect(results[0].offers.single.priceCents, 33995);
    expect(results[0].offers.single.sku, 'sku-1');
    expect(results[1].offers.single.priceCents, 16900);
    expect(results[1].offers.single.ean, '12345');
    expect(results[1].offers.single.observedAt, now);
    expect(results[2].store, Supermarket.jumbo);
    expect(results[2].unavailable, isTrue);
    expect(results[2].offers, isEmpty);
  });

  test(
    'Removes recipe quantities and translates ingredients for store search',
    () async {
      final source = SupermarketPriceSource(
        client: MockClient((request) async {
          if (request.url.host == 'supermercadosnacional.com') {
            expect(
              jsonDecode(request.url.queryParameters['variables']!)['term'],
              'huevo',
            );
            return http.Response(
              jsonEncode(national(name: 'Huevos Blancos 12 Und')),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          expect(request.url.pathSegments.last, 'huevo');
          return http.Response(
            jsonEncode(sirena(productName: 'Huevos Blancos 12 Und')),
            206,
          );
        }),
      );

      final results = await source.search('2 eggs');

      expect(results[0].offers, hasLength(1));
      expect(results[1].offers, hasLength(1));
    },
  );

  test(
    'Drops fuzzy results that do not match the requested ingredient',
    () async {
      final source = SupermarketPriceSource(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode(
              request.url.host == 'supermercadosnacional.com'
                  ? national(name: 'Batata dulce fresca')
                  : sirena(productName: 'Ají dulce rojo'),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );

      final results = await source.search('2 medium sweet potatoes');

      expect(results.first.offers, hasLength(1));
      expect(results.first.offers.single.product, 'Batata dulce fresca');
      expect(results[1].offers, isEmpty);
    },
  );

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
