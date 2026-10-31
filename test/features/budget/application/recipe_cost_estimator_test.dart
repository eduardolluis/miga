import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';
import 'package:miga/features/recipes/data/recipe_catalog.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';

void main() {
  test('Rejects related products that are not the ingredient', () {
    for (final pair in [
      (RecipeIngredient.tomatoes, 'Sopa De Tomate Linda 10.5 Oz'),
      (RecipeIngredient.tomatoes, 'Tomate Frito Solis 350 Gr'),
      (RecipeIngredient.garlic, 'Vinagre De Ajo 16 Oz'),
      (RecipeIngredient.basil, 'Tomates Con Albahaca 15 Oz'),
      (RecipeIngredient.eggs, 'Huevos De Codorniz 24 Uds'),
      (RecipeIngredient.carrot, 'Yogurt Zanahoria 150 Gr'),
      (RecipeIngredient.oliveOil, 'Mezcla Aceite Oliva Girasol 2L'),
      (RecipeIngredient.pepper, 'Adobo Con Pimienta 16 Oz'),
    ]) {
      expect(RecipeCostEstimator.matchesIngredient(pair.$1, pair.$2), isFalse);
    }
    expect(
      RecipeCostEstimator.matchesIngredient(
        RecipeIngredient.tomatoes,
        'Tomates frescos 1 Lb',
      ),
      isTrue,
    );
    expect(
      RecipeCostEstimator.packageAmount('Espinaca peso aprox. 1/2 libra'),
      isNull,
    );
    expect(
      RecipeCostEstimator.packageAmount('Espinaca 1/2 libra')!.$1,
      closeTo(226.796185, 0.001),
    );
  });

  test('Every recipe has explicit quantities for all of its ingredients', () {
    for (final recipe in RecipeCatalog.all) {
      final amounts = RecipeAmounts.values[recipe.id]!;
      expect(amounts.map((a) => a.ingredient).toSet(), recipe.ingredients);
      expect(amounts.every((a) => a.amount > 0), isTrue);
    }
  });

  test(
    'Converts package sizes but never guesses unknown or multipack sizes',
    () {
      expect(RecipeCostEstimator.packageAmount('Aceite 1 Lt'), (
        1000.0,
        CostUnit.milliliters,
      ));
      expect(RecipeCostEstimator.packageAmount('Huevos 30 Und/Paq'), (
        30.0,
        CostUnit.pieces,
      ));
      expect(
        RecipeCostEstimator.packageAmount('Arroz 2 Lb')!.$1,
        closeTo(907.18474, 0.001),
      );
      expect(RecipeCostEstimator.packageAmount('Pasta 500 g'), (
        500.0,
        CostUnit.grams,
      ));
      expect(RecipeCostEstimator.packageAmount('Milk 12 x 1 L'), isNull);
      expect(RecipeCostEstimator.packageAmount('Tomates frescos'), isNull);
    },
  );

  test(
    'Recipe costs use consumed fractions, not the cost of every package',
    () async {
      final recipe = RecipeCatalog.all.firstWhere(
        (r) => r.id == 'sweet-potato-egg',
      );
      var missing = false;
      final estimator = RecipeCostEstimator(
        search: (query) async {
          final title = switch (query) {
            'Batata' => 'Batata 1 kg',
            'Huevos' => 'Huevos 12 Und',
            'Espinaca' => 'Espinaca 100 g',
            'Aceite de oliva' => 'Aceite de oliva 1 L',
            'Sal' => 'Sal 1000 g',
            'Pimienta' =>
              missing ? 'Pimienta sin tamaño' : 'Pimienta negra 100 g',
            _ => throw StateError(query),
          };
          return [
            StoreSearchResult(
              Supermarket.jumbo,
              offers: [
                SupermarketOffer(
                  store: Supermarket.jumbo,
                  product: title,
                  sku: query,
                  presentation: title,
                  priceCents: 12000,
                  sourceUrl: 'https://jumbo.com.do/product',
                  observedAt: DateTime.now(),
                ),
              ],
            ),
          ];
        },
      );
      final cost = (await estimator.estimate([recipe])).single;
      // 400g batata 4800 + 2 eggs 2000 + 60g spinach 7200 + 15ml oil 180 + salt12 + pepper60.
      expect(cost.subtotalCents, 14252);
      expect(cost.complete, isTrue);
      expect(cost.fits(14252), isTrue);
      expect(cost.fits(14251), isFalse);
      missing = true;
      final incompleteEstimator = RecipeCostEstimator(search: (_) async => []);
      final incomplete = (await incompleteEstimator.estimate([recipe])).single;
      expect(incomplete.complete, isFalse);
      expect(incomplete.fits(100000), isFalse);
    },
  );

  test('Weekly allowance responds to remaining money, day and time', () {
    const budget = WeeklyBudget(limit: 2100, spent: 0, currency: 'DOP');
    expect(mealAllowanceCents(budget, DateTime(2026, 10, 26, 8)), 10000);
    expect(mealAllowanceCents(budget, DateTime(2026, 11, 1, 20)), 210000);
    expect(
      mealAllowanceCents(
        const WeeklyBudget(limit: 100, spent: 200, currency: 'DOP'),
        DateTime(2026, 11, 1),
      ),
      0,
    );
  });
}
