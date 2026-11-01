import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/groceries/data/grocery_price_estimator.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';

SupermarketOffer offer(
  int cents, {
  Supermarket store = Supermarket.jumbo,
  DateTime? date,
  String currency = 'DOP',
}) => SupermarketOffer(
  store: store,
  product: 'Arroz 5 lb',
  sku: 'rice',
  presentation: '5 lb',
  priceCents: cents,
  sourceUrl: 'https://jumbo.com.do/arroz',
  observedAt: date ?? DateTime.now(),
  currency: currency,
);

void main() {
  test('Previously saved wrong automatic estimates are excluded and can be cleared', () {
    final dried = SupermarketOffer(
      store: Supermarket.nacional,
      product: 'Mango Deshidratado 50 Gr',
      sku: 'wrong',
      presentation: '50 Gr',
      priceCents: 11995,
      sourceUrl: 'https://supermercadosnacional.com/mango',
      observedAt: DateTime.now(),
    );
    final item = const GroceryItem(
      'Mango',
      checked: true,
      ingredientId: 'mango',
      quantity: 6,
    ).withOffer(dried, estimated: true);
    expect(item.hasInvalidEstimate, isTrue);
    expect(item.totalCents, isNull);
    final cleared = item.withoutPrice();
    expect(cleared.checked, isTrue);
    expect(cleared.quantity, 6);
    expect(cleared.ingredientId, 'mango');
    expect(cleared.offer, isNull);
    expect(cleared.unitPriceCents, isNull);
  });

  test(
    'Grocery estimates apply the same fresh-product matching as recipes',
    () async {
      SupermarketOffer mango(String title, int cents) => SupermarketOffer(
        store: Supermarket.nacional,
        product: title,
        sku: title,
        presentation: title,
        priceCents: cents,
        sourceUrl: 'https://supermercadosnacional.com/mango',
        observedAt: DateTime.now(),
        categories: ['Frutas y Vegetales'],
      );
      final source = GroceryPriceEstimator(
        search: (_) async => [
          StoreSearchResult(
            Supermarket.nacional,
            offers: [
              mango('Mango Deshidratado 50 Gr', 1000),
              mango('Mango Grano De Oro, Und', 3900),
            ],
          ),
        ],
      );
      expect(
        (await source.estimate('Mango'))!.product,
        'Mango Grano De Oro, Und',
      );
      final missing = GroceryPriceEstimator(
        search: (_) async => [
          StoreSearchResult(
            Supermarket.nacional,
            offers: [mango('Mango Deshidratado 50 Gr', 1000)],
          ),
        ],
      );
      expect(await missing.estimate('Mango'), isNull);
    },
  );

  test('Estimates an actual package and caches without treating club bulk as equivalent', () async {
    var calls = 0;
    final estimator = GroceryPriceEstimator(
      search: (_) async {
        calls++;
        return [
          StoreSearchResult(
            Supermarket.jumbo,
            offers: [offer(30000), offer(20000)],
          ),
          StoreSearchResult(
            Supermarket.pricesmart,
            offers: [offer(10000, store: Supermarket.pricesmart)],
          ),
        ];
      },
    );
    final selected = await estimator.estimate('Arroz');
    expect(selected!.priceCents, 20000);
    expect(await estimator.estimate('arroz'), same(selected));
    expect(calls, 1);
    final item = const GroceryItem(
      'Rice',
      quantity: 2,
    ).withOffer(selected, estimated: true).withChecked(true);
    final restored = GroceryItem.fromJson(item.toJson());
    expect(restored.isEstimated, isTrue);
    expect(restored.checked, isTrue);
    expect(restored.totalCents, 40000);
    expect(restored.withOffer(selected).isEstimated, isFalse);
  });

  test(
    'Never fabricates an estimate for stale, unknown, zero or foreign prices',
    () async {
      final estimator = GroceryPriceEstimator(
        search: (_) async => [
          StoreSearchResult(
            Supermarket.jumbo,
            offers: [
              offer(0),
              offer(100, currency: 'USD'),
              offer(200, date: DateTime(2020)),
            ],
          ),
        ],
      );
      expect(await estimator.estimate('rice'), isNull);
      final failing = GroceryPriceEstimator(
        search: (_) async => throw StateError('offline'),
      );
      expect(await failing.estimate('rice'), isNull);
    },
  );
}
