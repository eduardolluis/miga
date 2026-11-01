import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';
import 'package:miga/features/recipes/data/recipe_catalog.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';

void main() {
  test('Fresh mango never becomes six packages of dried mango', () {
    SupermarketOffer mango(
      String title, {
      List<String> categories = const [],
    }) => SupermarketOffer(
      store: Supermarket.nacional,
      product: title,
      sku: title,
      presentation: title,
      priceCents: 3900,
      sourceUrl: 'https://supermercadosnacional.com/mango',
      observedAt: DateTime.now(),
      categories: categories,
    );
    const required = RecipeAmount(
      RecipeIngredient.mango,
      1,
      CostUnit.pieces,
      gramsPerPiece: 300,
    );
    expect(
      RecipeCostEstimator.purchaseCost(
        required,
        mango('Mango Deshidratado Carimango 50 Gr'),
      ).cents,
      isNull,
    );
    final fresh = RecipeCostEstimator.purchaseCost(
      required,
      mango('Mango Grano De Oro, Und', categories: ['Frutas y Vegetales']),
    );
    expect(fresh.purchaseCount, 1);
    expect(fresh.cents, 3900);
    expect(
      RecipeCostEstimator.purchaseCost(
        required.scaled(6),
        fresh.offer!,
      ).purchaseCount,
      6,
    );
  });

  test('Product forms and departments reject the actual false matches found in the audit', () {
    for (final pair in [
      (RecipeIngredient.salmon, 'Salmon En Lata Para Gatos Paws Premium 3 Onz'),
      (RecipeIngredient.pineapple, 'Pina Colada Goya 12 Oz'),
      (RecipeIngredient.yogurt, 'Yogur De Frambuesa Bajo En Grasa Kefir 8 Oz'),
      (RecipeIngredient.chicken, 'Pechuga De Pollo Con Hueso 1 Lb'),
      (RecipeIngredient.bread, 'Pan Pita Integral 12 Oz'),
      (RecipeIngredient.mango, 'Mango En Almibar 400 Gr'),
    ]) {
      expect(RecipeCostEstimator.matchesIngredient(pair.$1, pair.$2), isFalse);
    }
    final canned = SupermarketOffer(
      store: Supermarket.nacional,
      product: 'Hongos Champiñones Laminados 150 Gr',
      sku: 'm',
      presentation: '150 Gr',
      priceCents: 9995,
      sourceUrl: 'https://supermercadosnacional.com/m',
      observedAt: DateTime.now(),
      categories: ['Despensa', 'Conservas Vegetales'],
    );
    expect(
      RecipeCostEstimator.matchesOffer(RecipeIngredient.mushrooms, canned),
      isFalse,
    );
    final pet = SupermarketOffer(
      store: Supermarket.nacional,
      product: 'Salmon Premium 85 Gr',
      sku: 'p',
      presentation: '85 Gr',
      priceCents: 1000,
      sourceUrl: 'https://supermercadosnacional.com/p',
      observedAt: DateTime.now(),
      categories: ['Mascotas'],
    );
    expect(
      RecipeCostEstimator.matchesOffer(RecipeIngredient.salmon, pet),
      isFalse,
    );
    expect(
      RecipeCostEstimator.packageAmount('Papas Paq. (Aprox. 0.8 a 1 Libra)'),
      isNull,
    );
    expect(
      RecipeCostEstimator.packageAmount(
        'Fresas Paq. 0.72 Lb (Aprox. 16-18 Unidades)',
      )!.$1,
      closeTo(326.5865064, 0.001),
    );
  });

  test(
    'Changing servings chooses the lowest full-package outlay again',
    () async {
      SupermarketOffer oats(String name, int cents) => SupermarketOffer(
        store: Supermarket.nacional,
        product: name,
        sku: name,
        presentation: name,
        priceCents: cents,
        sourceUrl: 'https://supermercadosnacional.com/oats',
        observedAt: DateTime.now(),
      );
      final estimator = RecipeCostEstimator(
        search: (_) async => [
          StoreSearchResult(
            Supermarket.nacional,
            offers: [oats('Avena 100 g', 5000), oats('Avena 1 kg', 10000)],
          ),
        ],
      );
      final recipe = RecipeCatalog.all.firstWhere((r) => r.id == 'banana-oats');
      final base = (await estimator.estimate([recipe])).single;
      expect(base.ingredients.first.cents, 5000);
      final larger = estimator.costFromCache(recipe.withServings(12));
      expect(larger.ingredients.first.cents, 10000);
      expect(larger.ingredients.first.purchaseCount, 1);
    },
  );

  test('Rejects related products that are not the ingredient', () {
    for (final pair in [
      (RecipeIngredient.tomatoes, 'Sopa De Tomate Linda 10.5 Oz'),
      (RecipeIngredient.tomatoes, 'Tomate Frito Solis 350 Gr'),
      (RecipeIngredient.tomatoes, 'Tomate Passata Mutti 400 Gr'),
      (RecipeIngredient.onion, 'Cebolla Molida Oriente Frasco 85 Gr'),
      (RecipeIngredient.walnuts, 'Nueces Mixtas Wala 100 Gr'),
      (RecipeIngredient.walnuts, 'Nueces Dietz De Turquía Dietz & Watson 2 Oz'),
      (RecipeIngredient.walnuts, 'Nueces De Macadamia 8 Oz'),
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

  test('new catalogue ingredient price matches stay conservative', () {
    expect(
      RecipeCostEstimator.matchesIngredient(
        RecipeIngredient.tuna,
        'Atún en agua 170 g',
      ),
      isTrue,
    );
    expect(
      RecipeCostEstimator.matchesIngredient(
        RecipeIngredient.mushrooms,
        'Champiñones frescos 250 g',
      ),
      isTrue,
    );
    expect(
      RecipeCostEstimator.matchesIngredient(
        RecipeIngredient.pineapple,
        'Piña fresca 1 kg',
      ),
      isTrue,
    );
    expect(
      RecipeCostEstimator.matchesIngredient(
        RecipeIngredient.tortilla,
        'Tortilla de maíz 6 unidades',
      ),
      isFalse,
    );
    expect(
      RecipeCostEstimator.matchesIngredient(
        RecipeIngredient.tortilla,
        'Tortillas de trigo 10 unidades',
      ),
      isTrue,
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

  test('Recipe costs cover whole packages, including seasonings', () async {
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
    // Each of the six ingredients needs one complete package.
    expect(cost.subtotalCents, 72000);
    expect(cost.complete, isTrue);
    expect(cost.fits(72000), isTrue);
    expect(cost.fits(71999), isFalse);
    missing = true;
    final incompleteEstimator = RecipeCostEstimator(search: (_) async => []);
    final incomplete = (await incompleteEstimator.estimate([recipe])).single;
    expect(incomplete.complete, isFalse);
    expect(incomplete.fits(100000), isFalse);
  });

  test('Purchases round up to complete packs and individually sold units', () {
    SupermarketOffer offer(String title, int cents) => SupermarketOffer(
      store: Supermarket.jumbo,
      product: title,
      sku: title,
      presentation: title,
      priceCents: cents,
      sourceUrl: 'https://jumbo.com.do/product',
      observedAt: DateTime.now(),
    );
    const small = RecipeAmount(RecipeIngredient.pasta, 180, CostUnit.grams);
    const large = RecipeAmount(RecipeIngredient.pasta, 600, CostUnit.grams);
    final pack = offer('Pasta 400 g', 10000);
    expect(RecipeCostEstimator.purchaseCost(small, pack).cents, 10000);
    final two = RecipeCostEstimator.purchaseCost(large, pack);
    expect(two.cents, 20000);
    expect(two.purchaseCount, 2);
    const eggs = RecipeAmount(RecipeIngredient.eggs, 2, CostUnit.pieces);
    expect(
      RecipeCostEstimator.purchaseCost(eggs, offer('Huevos 1 Und', 1500)).cents,
      3000,
    );
    expect(
      RecipeCostEstimator.purchaseCost(
        eggs,
        offer('Huevos 12 Und', 12000),
      ).cents,
      12000,
    );
  });

  test('Weighted produce, individual avocados, Onz packs and liquid broth are priceable', () {
    SupermarketOffer offer(String name) => SupermarketOffer(
      store: Supermarket.nacional,
      product: name,
      sku: name,
      presentation: name,
      priceCents: 22995,
      sourceUrl: 'https://supermercadosnacional.com/product',
      observedAt: DateTime.now(),
    );
    expect(
      RecipeCostEstimator.purchaseCost(
        const RecipeAmount(
          RecipeIngredient.vegetableStock,
          300,
          CostUnit.milliliters,
        ),
        offer('Caldo Liquido De Vegetales Full Circle 32 Onz'),
      ).purchaseCount,
      1,
    );
    expect(
      RecipeCostEstimator.purchaseCost(
        const RecipeAmount(RecipeIngredient.tofu, 300, CostUnit.grams),
        offer('Tofu Firme 14 Onz'),
      ).purchaseCount,
      1,
    );
    expect(
      RecipeCostEstimator.purchaseCost(
        const RecipeAmount(RecipeIngredient.avocado, 1, CostUnit.pieces),
        offer('Aguacate Criollo, Und'),
      ).purchaseCount,
      1,
    );
    expect(
      RecipeCostEstimator.purchaseCost(
        const RecipeAmount(RecipeIngredient.garlic, 4, CostUnit.grams),
        offer('Ajo Selecto Paquete 4 Uds'),
      ).purchaseCount,
      1,
    );
    final carrot = SupermarketOffer(
      store: Supermarket.sirena,
      product: 'Zanahoria Fresca Lb',
      sku: 'carrot',
      presentation: '0.5 lb',
      priceCents: 1500,
      sourceUrl: 'https://nuevo.sirena.do/product/p',
      observedAt: DateTime.now(),
      purchaseQuantity: 226.796185,
      measurementUnit: 'g',
    );
    expect(
      RecipeCostEstimator.purchaseCost(
        const RecipeAmount(RecipeIngredient.carrot, 120, CostUnit.grams),
        carrot,
      ).cents,
      1500,
    );
    expect(
      RecipeCostEstimator.purchaseCost(
        const RecipeAmount(RecipeIngredient.carrot, 300, CostUnit.grams),
        carrot,
      ).cents,
      3000,
    );
  });

  test('Weekly allowance responds to remaining money, day and time', () {
    const budget = WeeklyBudget(limit: 2100, spent: 0, currency: 'DOP');
    expect(remainingMealSlots(DateTime(2026, 10, 26, 8)), 21);
    expect(remainingMealSlots(DateTime(2026, 11, 1, 20)), 1);
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
