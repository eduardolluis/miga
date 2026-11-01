import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/domain/recipe_amount.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
export 'package:miga/features/recipes/domain/recipe_amount.dart';

abstract final class RecipeAmounts {
  static List<RecipeAmount> forRecipe(Recipe recipe) => [
    for (final amount in recipe.amounts)
      amount.scaled(recipe.servings / recipe.baseServings),
  ];

  // Canonical units for manual price entry and pantry quantities.
  // Recipe-specific quantities always come from the published catalog.
  static CostUnit unitFor(RecipeIngredient ingredient) => switch (ingredient) {
    RecipeIngredient.milk ||
    RecipeIngredient.oliveOil ||
    RecipeIngredient.vegetableStock => CostUnit.milliliters,
    RecipeIngredient.banana ||
    RecipeIngredient.avocado ||
    RecipeIngredient.eggs ||
    RecipeIngredient.mango ||
    RecipeIngredient.lemon ||
    RecipeIngredient.apple ||
    RecipeIngredient.tortilla => CostUnit.pieces,
    _ => CostUnit.grams,
  };
}
