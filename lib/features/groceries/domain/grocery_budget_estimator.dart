import 'dart:math' as math;

import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';

/// Dated Dominican budget rates for all recipe ingredients.
/// These are portion-use estimates, not current supermarket quotes.
abstract final class GroceryBudgetEstimator {
  static const _fallbackDopPerUnknownItem = 75.0;

  static const _rates = <RecipeIngredient, _IngredientRate>{
    RecipeIngredient.oats: _IngredientRate(CostUnit.grams, .18),
    RecipeIngredient.milk: _IngredientRate(CostUnit.milliliters, .085),
    RecipeIngredient.banana: _IngredientRate(CostUnit.pieces, 13),
    RecipeIngredient.walnuts: _IngredientRate(CostUnit.grams, 1.6),
    RecipeIngredient.cinnamon: _IngredientRate(CostUnit.grams, 1.2),
    RecipeIngredient.bread: _IngredientRate(CostUnit.grams, .2),
    RecipeIngredient.avocado: _IngredientRate(CostUnit.pieces, 65),
    RecipeIngredient.eggs: _IngredientRate(CostUnit.pieces, 10),
    RecipeIngredient.tomatoes: _IngredientRate(CostUnit.grams, .12),
    RecipeIngredient.oliveOil: _IngredientRate(CostUnit.milliliters, 1.15),
    RecipeIngredient.salt: _IngredientRate(CostUnit.grams, .12),
    RecipeIngredient.pepper: _IngredientRate(CostUnit.grams, 2.1),
    RecipeIngredient.yogurt: _IngredientRate(CostUnit.grams, .42),
    RecipeIngredient.mango: _IngredientRate(CostUnit.pieces, 55),
    RecipeIngredient.strawberries: _IngredientRate(CostUnit.grams, .68),
    RecipeIngredient.granola: _IngredientRate(CostUnit.grams, .47),
    RecipeIngredient.salmon: _IngredientRate(CostUnit.grams, 1.75),
    RecipeIngredient.potatoes: _IngredientRate(CostUnit.grams, .105),
    RecipeIngredient.broccoli: _IngredientRate(CostUnit.grams, .3),
    RecipeIngredient.lemon: _IngredientRate(CostUnit.pieces, 16),
    RecipeIngredient.herbs: _IngredientRate(CostUnit.grams, 1.3),
    RecipeIngredient.chicken: _IngredientRate(CostUnit.grams, .46),
    RecipeIngredient.rice: _IngredientRate(CostUnit.grams, .082),
    RecipeIngredient.carrot: _IngredientRate(CostUnit.grams, .09),
    RecipeIngredient.garlic: _IngredientRate(CostUnit.grams, .4),
    RecipeIngredient.chickpeas: _IngredientRate(CostUnit.grams, .22),
    RecipeIngredient.cucumber: _IngredientRate(CostUnit.grams, .15),
    RecipeIngredient.onion: _IngredientRate(CostUnit.grams, .125),
    RecipeIngredient.pasta: _IngredientRate(CostUnit.grams, .13),
    RecipeIngredient.basil: _IngredientRate(CostUnit.grams, 2),
    RecipeIngredient.cheese: _IngredientRate(CostUnit.grams, .75),
    RecipeIngredient.sweetPotato: _IngredientRate(CostUnit.grams, .14),
    RecipeIngredient.spinach: _IngredientRate(CostUnit.grams, .33),
    RecipeIngredient.lentils: _IngredientRate(CostUnit.grams, .21),
    RecipeIngredient.celery: _IngredientRate(CostUnit.grams, .18),
    RecipeIngredient.vegetableStock: _IngredientRate(
      CostUnit.milliliters,
      .055,
    ),
    RecipeIngredient.apple: _IngredientRate(CostUnit.pieces, 32),
    RecipeIngredient.peanutButter: _IngredientRate(CostUnit.grams, .9),
    RecipeIngredient.tortilla: _IngredientRate(CostUnit.pieces, 22),
    RecipeIngredient.blackBeans: _IngredientRate(CostUnit.grams, .18),
    RecipeIngredient.tuna: _IngredientRate(CostUnit.grams, .84),
    RecipeIngredient.groundBeef: _IngredientRate(CostUnit.grams, .7),
    RecipeIngredient.bellPepper: _IngredientRate(CostUnit.grams, .22),
    RecipeIngredient.mushrooms: _IngredientRate(CostUnit.grams, .68),
    RecipeIngredient.zucchini: _IngredientRate(CostUnit.grams, .24),
    RecipeIngredient.pineapple: _IngredientRate(CostUnit.grams, .18),
    RecipeIngredient.tofu: _IngredientRate(CostUnit.grams, .75),
    RecipeIngredient.quinoa: _IngredientRate(CostUnit.grams, .48),
  };

  static const _gramsPerPiece = <RecipeIngredient, double>{
    RecipeIngredient.banana: 120,
    RecipeIngredient.avocado: 200,
    RecipeIngredient.eggs: 50,
    RecipeIngredient.mango: 300,
    RecipeIngredient.lemon: 60,
    RecipeIngredient.apple: 180,
    RecipeIngredient.tortilla: 40,
    RecipeIngredient.tomatoes: 120,
    RecipeIngredient.potatoes: 170,
    RecipeIngredient.broccoli: 500,
    RecipeIngredient.chicken: 180,
    RecipeIngredient.carrot: 80,
    RecipeIngredient.garlic: 50,
    RecipeIngredient.cucumber: 300,
    RecipeIngredient.onion: 150,
    RecipeIngredient.sweetPotato: 200,
    RecipeIngredient.celery: 40,
    RecipeIngredient.bellPepper: 150,
    RecipeIngredient.mushrooms: 100,
    RecipeIngredient.zucchini: 200,
    RecipeIngredient.pineapple: 900,
  };

  /// Returns an approximate total in cents for DOP. A known ingredient uses
  /// its dated canonical rate; an unrecognized manual item uses RD$75/item.
  /// Non-DOP currencies deliberately have no converted estimate.
  static int? estimateTotalCents({
    required RecipeIngredient? ingredient,
    required double? requiredAmount,
    required CostUnit? requiredUnit,
    required int quantity,
    required String currency,
  }) {
    if (currency != 'DOP' || quantity < 1) return null;
    final rate = _rates[ingredient];
    if (rate == null) {
      return (_fallbackDopPerUnknownItem * quantity * 100).round();
    }

    final amount = requiredAmount;
    final unit = requiredUnit;
    if (amount != null && amount > 0 && unit != null) {
      final normalized = _convert(amount, unit, rate.unit, ingredient!);
      if (normalized != null) {
        return math.max(1, (normalized * rate.dopPerUnit * 100).round());
      }
    }

    // Manual lines have no recipe amount, so use a typical 500 g, 1 L, or
    // one-piece purchase unit, multiplied by the user's chosen quantity.
    final typical = switch (rate.unit) {
      CostUnit.grams => 500.0,
      CostUnit.milliliters => 1000.0,
      CostUnit.pieces => 1.0,
    };
    return math.max(1, (typical * rate.dopPerUnit * quantity * 100).round());
  }

  static double? _convert(
    double amount,
    CostUnit from,
    CostUnit to,
    RecipeIngredient ingredient,
  ) {
    if (from == to) return amount;
    final gramsPerPiece = _gramsPerPiece[ingredient];
    if (from == CostUnit.pieces &&
        to == CostUnit.grams &&
        gramsPerPiece != null) {
      return amount * gramsPerPiece;
    }
    if (from == CostUnit.grams &&
        to == CostUnit.pieces &&
        gramsPerPiece != null) {
      return amount / gramsPerPiece;
    }
    return null;
  }
}

class _IngredientRate {
  const _IngredientRate(this.unit, this.dopPerUnit);
  final CostUnit unit;
  final double dopPerUnit;
}
