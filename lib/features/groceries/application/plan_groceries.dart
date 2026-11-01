import 'dart:math' as math;

import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/pantry/domain/pantry_item.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';

List<GroceryItem> groceriesForPlan({
  required Iterable<Recipe> recipes,
  required List<GroceryItem> existing,
  List<PantryItem> pantry = const [],
  Set<RecipeIngredient> excluded = const {},
  String language = 'es',
  String currency = 'DOP',
}) {
  final needed = <RecipeIngredient, RecipeAmount>{};
  for (final recipe in recipes) {
    for (final amount in RecipeAmounts.forRecipe(recipe)) {
      if (excluded.contains(amount.ingredient)) continue;
      final previous = needed[amount.ingredient];
      needed[amount.ingredient] = RecipeAmount(
        amount.ingredient,
        (previous?.amount ?? 0) + amount.amount,
        amount.unit,
        gramsPerPiece: amount.gramsPerPiece,
      );
    }
  }
  final remaining = List<GroceryItem>.of(
    existing.where((item) => !item.fromPlan),
  );
  final result = <GroceryItem>[];
  for (final amount in needed.values) {
    var missing = amount.amount;
    for (final stock in pantry.where(
      (p) => p.ingredient == amount.ingredient,
    )) {
      if (stock.unit == amount.unit) {
        missing -= stock.amount;
      } else if (stock.unit == CostUnit.grams &&
          amount.unit == CostUnit.pieces &&
          amount.gramsPerPiece != null) {
        missing -= stock.amount / amount.gramsPerPiece!;
      } else if (stock.unit == CostUnit.pieces &&
          amount.unit == CostUnit.grams &&
          amount.gramsPerPiece != null) {
        missing -= stock.amount * amount.gramsPerPiece!;
      }
    }
    if (missing <= 0.000001) continue;
    GroceryItem? previous;
    for (final item in existing) {
      if (item.ingredientId == amount.ingredient.name ||
          item.name.toLowerCase() == amount.ingredient.es.toLowerCase() ||
          item.name.toLowerCase() == amount.ingredient.en.toLowerCase()) {
        previous = item;
        break;
      }
    }
    if (previous != null) remaining.remove(previous);
    var quantity = previous?.manualQuantity == true ? previous!.quantity : 1;
    if (previous?.manualQuantity != true) {
      final pack = previous?.offer == null
          ? null
          : RecipeCostEstimator.packageForOffer(previous!.offer!);
      if (pack != null && pack.$2 == amount.unit) {
        quantity = math.max(1, (missing / pack.$1).ceil());
      } else if (amount.unit == CostUnit.pieces) {
        quantity = missing.ceil();
      }
    }
    result.add(
      GroceryItem(
        amount.ingredient.label(language),
        checked: previous?.checked ?? false,
        quantity: quantity,
        currency: previous?.currency ?? currency,
        unitPriceCents: previous?.unitPriceCents,
        reference: previous?.reference,
        offer: previous?.offer,
        isEstimated: previous?.isEstimated ?? true,
        ingredientId: amount.ingredient.name,
        requiredAmount: missing,
        requiredUnit: amount.unit,
        manualQuantity: previous?.manualQuantity ?? false,
        planGenerated: true,
      ),
    );
  }
  return [...result, ...remaining];
}
