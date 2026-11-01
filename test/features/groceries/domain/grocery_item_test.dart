import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/groceries/domain/grocery_price_reference.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';

void main() {
  test(
    'Egg carton notation keeps six eggs separate from one purchase package',
    () {
      final offer = SupermarketOffer(
        store: Supermarket.sirena,
        product: 'Huevos Extra Grandes Blanco 6/1 Endy',
        sku: 'eggs',
        presentation: '1 Und.',
        priceCents: 6500,
        sourceUrl: 'https://nuevo.sirena.do/huevos/p',
        observedAt: DateTime.now(),
      );
      expect(RecipeCostEstimator.packageForOffer(offer), (
        6.0,
        CostUnit.pieces,
      ));
      expect(RecipeCostEstimator.packageAmount('Huevos Endy 30/1'), (
        30.0,
        CostUnit.pieces,
      ));
      final item = const GroceryItem('2 eggs')
          .normalizedForPricing()
          .withOffer(offer, estimated: true);
      expect(item.requiredAmount, 2);
      expect(item.ingredientForPricing, RecipeIngredient.eggs);
      expect(item.quantity, 1);
      expect(item.totalCents, 6500);
      final restored = GroceryItem.fromJson({...item.toJson(), 'quantity': 2});
      expect(restored.quantity, 1);
      expect(restored.totalCents, 6500);
      expect(
        GroceryItem.fromJson({
          ...item.toJson(),
          'quantity': 2,
          'manualQuantity': true,
        }).quantity,
        2,
      );
    },
  );

  test('Recipe shopping text resolves its ingredient without matching arbitrary prose', () {
    expect(
      const GroceryItem('2 cups spinach').ingredientForPricing,
      RecipeIngredient.spinach,
    );
    expect(
      const GroceryItem('1 tablespoon olive oil').ingredientForPricing,
      RecipeIngredient.oliveOil,
    );
    expect(
      const GroceryItem('2 medium sweet potatoes').ingredientForPricing,
      RecipeIngredient.sweetPotato,
    );
    expect(
      const GroceryItem('1 taza leche').ingredientForPricing,
      RecipeIngredient.milk,
    );
    expect(const GroceryItem('egg shampoo').ingredientForPricing, isNull);
  });
  test(
    'Expired online prices remain auditable but cannot silently enter totals',
    () {
      final now = DateTime.now();
      final offer = SupermarketOffer(
        store: Supermarket.nacional,
        product: 'Rice',
        sku: 'sku',
        presentation: '5 Lb',
        priceCents: 20000,
        sourceUrl: 'https://supermercadosnacional.com/rice',
        observedAt: now.subtract(const Duration(hours: 25)),
      );
      expect(offer.isStaleAt(now), isTrue);
      final item = const GroceryItem('Rice').withOffer(offer);
      expect(item.unitPriceCents, 20000);
      expect(item.totalCents, isNull);
      final totals = GroceryTotals([item], 'DOP');
      expect(totals.subtotalCents, 0);
      expect(totals.missing, 1);
    },
  );
  test('Legacy items remain unpriced; zero is a known price; currencies stay separate', () {
    final legacy = GroceryItem.fromJson({'name': 'Pan', 'checked': false});
    expect(legacy.unitPriceCents, isNull);
    expect(legacy.quantity, 1);
    final totals = GroceryTotals([
      legacy,
      const GroceryItem('Eggs', unitPriceCents: 12050, quantity: 2),
      const GroceryItem('Free', unitPriceCents: 0),
      const GroceryItem('Milk', unitPriceCents: 300, currency: 'USD'),
    ], 'DOP');
    expect(totals.subtotalCents, 24100);
    expect(totals.priced, 2);
    expect(totals.missing, 2);
  });

  test('Toggling cart status and reloading preserve prices, quantities and provenance', () {
    const reference = GroceryPriceReference(
      product: 'Arroz',
      presentation: 'Funda 10 Lb.',
      priceCents: 33374,
      month: 'Septiembre',
      year: 2026,
      segment: 'supermercados grandes',
      sourceUrl: 'https://proconsumidor.gob.do/prices.csv',
    );
    final item = const GroceryItem(
      'Rice',
      unitPriceCents: 33374,
      quantity: 2,
      reference: reference,
    ).withChecked(true);
    final restored = GroceryItem.fromJson(item.toJson());
    expect(restored.checked, isTrue);
    expect(restored.totalCents, 66748);
    expect(restored.reference!.presentation, 'Funda 10 Lb.');
    expect(restored.reference!.month, 'Septiembre');
    expect(restored.reference!.sourceUrl, reference.sourceUrl);
  });
  test('Projected basket excludes checked items to avoid double counting', () {
    final items = [
      const GroceryItem('Bought', checked: true, unitPriceCents: 8000),
      const GroceryItem('Needed', unitPriceCents: 4500, quantity: 2),
      const GroceryItem('Unknown'),
    ];
    final all = GroceryTotals(items, 'DOP');
    final pending = GroceryTotals(items, 'DOP', includeChecked: false);
    expect(all.subtotalCents, 17000);
    expect(pending.subtotalCents, 9000);
    expect(pending.priced, 1);
    expect(pending.missing, 1);
  });

  test('Invalid persisted negative prices never enter projected totals', () {
    const broken = GroceryItem('Invalid', unitPriceCents: -2500);
    expect(broken.totalCents, isNull);
    expect(GroceryTotals([broken], 'DOP').missing, 1);
  });
}
