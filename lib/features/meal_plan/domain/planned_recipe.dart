import 'package:miga/features/recipes/data/recipe_catalog.dart';
import 'package:miga/features/recipes/domain/recipe.dart';

/// Stable IDs survive language changes. Plain v1 meal names remain readable.
class PlannedRecipe {
  const PlannedRecipe(this.recipeId, this.servings);
  final String recipeId;
  final int servings;
  String encode() => '@miga:$recipeId:$servings';

  Recipe? get recipe {
    for (final recipe in RecipeCatalog.all) {
      if (recipe.id == recipeId) return recipe.withServings(servings);
    }
    return null;
  }

  static PlannedRecipe? parse(String? value) {
    if (value == null) return null;
    if (value.startsWith('@miga:')) {
      final parts = value.split(':');
      if (parts.length != 3) return null;
      final servings = int.tryParse(parts[2]);
      if (servings == null || servings < 1 || servings > 24) return null;
      final entry = PlannedRecipe(parts[1], servings);
      return entry.recipe == null ? null : entry;
    }
    final name = value.trim().toLowerCase();
    for (final recipe in RecipeCatalog.all) {
      if (recipe.es.title.toLowerCase() == name ||
          recipe.en.title.toLowerCase() == name) {
        return PlannedRecipe(recipe.id, recipe.servings);
      }
    }
    return null;
  }
}
