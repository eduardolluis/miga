import 'package:miga/features/recipes/domain/recipe_ingredient.dart';

enum CostUnit { grams, milliliters, pieces }

class RecipeAmount {
  const RecipeAmount(
    this.ingredient,
    this.amount,
    this.unit, {
    this.gramsPerPiece,
  });
  final RecipeIngredient ingredient;
  final double amount;
  final CostUnit unit;
  final double? gramsPerPiece;

  RecipeAmount scaled(double factor) => RecipeAmount(
    ingredient,
    amount * factor,
    unit,
    gramsPerPiece: gramsPerPiece,
  );
}
