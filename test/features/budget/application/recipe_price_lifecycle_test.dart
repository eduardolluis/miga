import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/data/recipe_price_store.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';

import '../../../support/recipe_catalog.dart';

List<StoreSearchResult> catalog(String query) {
  final title = switch (query.toLowerCase()) {
    'avena' => 'Avena 100 g',
    'leche entera' => 'Leche Entera 1 L',
    'guineo maduro' => 'Guineo Maduro 1 Und',
    'nueces' => 'Nueces Peladas 100 g',
    'canela' => 'Canela Molida 100 g',
    _ => throw StateError(query),
  };
  return [
    StoreSearchResult(
      Supermarket.nacional,
      offers: [
        SupermarketOffer(
          store: Supermarket.nacional,
          product: title,
          sku: query,
          presentation: title,
          priceCents: 10000,
          sourceUrl: 'https://supermercadosnacional.com/test',
          observedAt: DateTime.now(),
        ),
      ],
    ),
  ];
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Valid prices survive a new estimator and are visible without opening recipes', () async {
    final recipe = RecipeCatalog.all.first;
    final first = RecipeCostEstimator(
      priceStore: LocalRecipePriceStore(),
      search: (q) async => catalog(q),
    );
    final beforeRestart = (await first.estimate([recipe])).single;
    expect(beforeRestart.complete, isTrue);
    final afterRestart = RecipeCostEstimator(
      priceStore: LocalRecipePriceStore(),
      search: (_) async => throw StateError('offline'),
    );
    await afterRestart.restorePrices();
    final restored = afterRestart.costFromCache(recipe);
    expect(restored.complete, isTrue);
    expect(restored.subtotalCents, beforeRestart.subtotalCents);
  });

  test(
    'Price progress is published while other ingredients are still pending',
    () async {
      final gate = Completer<void>();
      final firstProgress = Completer<void>();
      final nextBatch = Completer<void>();
      var updates = 0;
      final estimator = RecipeCostEstimator(
        priceStore: LocalRecipePriceStore(),
        search: (q) async {
          if (q.toLowerCase() == 'canela') {
            nextBatch.complete();
            await gate.future;
          }
          return catalog(q);
        },
      );
      final recipe = RecipeCatalog.all.first;
      final pending = estimator.estimate(
        [recipe],
        onProgress: () {
          updates++;
          if (!firstProgress.isCompleted) firstProgress.complete();
        },
      );
      await firstProgress.future;
      expect(
        estimator.costFromCache(recipe).ingredients.any((i) => i.cents != null),
        isTrue,
      );
      expect(estimator.costFromCache(recipe).complete, isFalse);
      await nextBatch.future;
      final restarted = RecipeCostEstimator(
        priceStore: LocalRecipePriceStore(),
        search: (_) async => [],
      );
      await restarted.restorePrices();
      expect(
        restarted
            .costFromCache(recipe)
            .ingredients
            .where((i) => i.cents != null)
            .length,
        3,
      );
      gate.complete();
      expect((await pending).single.complete, isTrue);
      expect(updates, recipe.ingredients.length);
    },
  );

  test(
    'Stored expired quotes and wrong product forms are not restored',
    () async {
      final store = LocalRecipePriceStore();
      await store.save({
        'oats': [
          SupermarketOffer(
            store: Supermarket.nacional,
            product: 'Avena 100 g',
            sku: 'old',
            presentation: '100 g',
            priceCents: 10000,
            sourceUrl: 'https://supermercadosnacional.com/old',
            observedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
        'mango': [
          SupermarketOffer(
            store: Supermarket.nacional,
            product: 'Mango Deshidratado 50 g',
            sku: 'wrong',
            presentation: '50 g',
            priceCents: 10000,
            sourceUrl: 'https://supermercadosnacional.com/wrong',
            observedAt: DateTime.now(),
          ),
        ],
      });
      final estimator = RecipeCostEstimator(
        priceStore: store,
        search: (_) async => [],
      );
      await estimator.restorePrices();
      for (final recipe in RecipeCatalog.all) {
        expect(
          estimator
              .costFromCache(recipe)
              .ingredients
              .every((i) => i.cents == null),
          isTrue,
        );
      }
    },
  );
}
