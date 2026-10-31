import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
import 'package:miga/features/recipes/domain/recipe.dart';

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

// Kitchen estimates for the catalog's two-serving recipes, including seasoning.
// Produce weights and "to taste" quantities are assumptions, not measured yields.
abstract final class RecipeAmounts {
  static List<RecipeAmount> forRecipe(Recipe recipe) => [
    for (final amount in values[recipe.id] ?? <RecipeAmount>[])
      amount.scaled(recipe.servings / 2),
  ];
  static const g = CostUnit.grams;
  static const ml = CostUnit.milliliters;
  static const pc = CostUnit.pieces;
  static const values = <String, List<RecipeAmount>>{
    'banana-oats': [
      RecipeAmount(RecipeIngredient.oats, 80, g),
      RecipeAmount(RecipeIngredient.milk, 480, ml),
      RecipeAmount(RecipeIngredient.banana, 1, pc, gramsPerPiece: 120),
      RecipeAmount(RecipeIngredient.walnuts, 14, g),
      RecipeAmount(RecipeIngredient.cinnamon, 1, g),
    ],
    'avocado-toast': [
      RecipeAmount(RecipeIngredient.bread, 60, g),
      RecipeAmount(RecipeIngredient.avocado, 1, pc, gramsPerPiece: 200),
      RecipeAmount(RecipeIngredient.eggs, 2, pc),
      RecipeAmount(RecipeIngredient.tomatoes, 100, g),
      RecipeAmount(RecipeIngredient.oliveOil, 5, ml),
      RecipeAmount(RecipeIngredient.salt, 1, g),
      RecipeAmount(RecipeIngredient.pepper, 0.5, g),
    ],
    'yogurt-fruit': [
      RecipeAmount(RecipeIngredient.yogurt, 480, g),
      RecipeAmount(RecipeIngredient.mango, 1, pc, gramsPerPiece: 300),
      RecipeAmount(RecipeIngredient.strawberries, 90, g),
      RecipeAmount(RecipeIngredient.granola, 60, g),
    ],
    'lemon-salmon': [
      RecipeAmount(RecipeIngredient.salmon, 300, g),
      RecipeAmount(RecipeIngredient.potatoes, 300, g),
      RecipeAmount(RecipeIngredient.broccoli, 180, g),
      RecipeAmount(RecipeIngredient.lemon, 1, pc, gramsPerPiece: 60),
      RecipeAmount(RecipeIngredient.oliveOil, 15, ml),
      RecipeAmount(RecipeIngredient.herbs, 2, g),
      RecipeAmount(RecipeIngredient.salt, 1, g),
      RecipeAmount(RecipeIngredient.pepper, 0.5, g),
    ],
    'chicken-rice': [
      RecipeAmount(RecipeIngredient.chicken, 250, g),
      RecipeAmount(RecipeIngredient.rice, 140, g),
      RecipeAmount(RecipeIngredient.carrot, 80, g),
      RecipeAmount(RecipeIngredient.broccoli, 90, g),
      RecipeAmount(RecipeIngredient.oliveOil, 15, ml),
      RecipeAmount(RecipeIngredient.garlic, 3, g),
      RecipeAmount(RecipeIngredient.salt, 1, g),
      RecipeAmount(RecipeIngredient.pepper, 0.5, g),
    ],
    'chickpea-salad': [
      RecipeAmount(RecipeIngredient.chickpeas, 320, g),
      RecipeAmount(RecipeIngredient.avocado, 1, pc, gramsPerPiece: 200),
      RecipeAmount(RecipeIngredient.tomatoes, 120, g),
      RecipeAmount(RecipeIngredient.cucumber, 150, g),
      RecipeAmount(RecipeIngredient.onion, 40, g),
      RecipeAmount(RecipeIngredient.lemon, 1, pc, gramsPerPiece: 60),
      RecipeAmount(RecipeIngredient.oliveOil, 15, ml),
    ],
    'tomato-pasta': [
      RecipeAmount(RecipeIngredient.pasta, 180, g),
      RecipeAmount(RecipeIngredient.tomatoes, 240, g),
      RecipeAmount(RecipeIngredient.garlic, 3, g),
      RecipeAmount(RecipeIngredient.oliveOil, 15, ml),
      RecipeAmount(RecipeIngredient.basil, 5, g),
      RecipeAmount(RecipeIngredient.cheese, 20, g),
    ],
    'sweet-potato-egg': [
      RecipeAmount(RecipeIngredient.sweetPotato, 400, g),
      RecipeAmount(RecipeIngredient.eggs, 2, pc),
      RecipeAmount(RecipeIngredient.spinach, 60, g),
      RecipeAmount(RecipeIngredient.oliveOil, 15, ml),
      RecipeAmount(RecipeIngredient.salt, 1, g),
      RecipeAmount(RecipeIngredient.pepper, 0.5, g),
    ],
    'lentil-soup': [
      RecipeAmount(RecipeIngredient.lentils, 400, g),
      RecipeAmount(RecipeIngredient.carrot, 80, g),
      RecipeAmount(RecipeIngredient.celery, 40, g),
      RecipeAmount(RecipeIngredient.onion, 80, g),
      RecipeAmount(RecipeIngredient.tomatoes, 120, g),
      RecipeAmount(RecipeIngredient.vegetableStock, 480, ml),
      RecipeAmount(RecipeIngredient.oliveOil, 15, ml),
    ],
  };
}
