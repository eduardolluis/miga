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
