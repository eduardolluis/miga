import 'package:miga/features/recipes/domain/recipe.dart';

/// Stable IDs and original portions survive catalog updates and locale changes.
class PlannedRecipe {
  const PlannedRecipe(this.recipeId, this.servings);
  final String recipeId;
  final int servings;
  String encode() => '@miga:$recipeId:$servings';
  Recipe? resolve(Iterable<Recipe> recipes) {
    for (final recipe in recipes) {
      if (recipe.id == recipeId) return recipe.withServings(servings);
    }
    return null;
  }

  static PlannedRecipe? parse(
    String? value, {
    Iterable<Recipe> recipes = const [],
  }) {
    if (value == null) return null;
    if (value.startsWith('@miga:')) {
      final parts = value.split(':');
      if (parts.length != 3 ||
          !RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(parts[1])) {
        return null;
      }
      final servings = int.tryParse(parts[2]);
      if (servings == null || servings < 1 || servings > 24) return null;
      return PlannedRecipe(parts[1], servings);
    }
    final name = value.trim().toLowerCase();
    for (final recipe in recipes) {
      if (recipe.es.title.toLowerCase() == name ||
          recipe.en.title.toLowerCase() == name) {
        return PlannedRecipe(recipe.id, recipe.servings);
      }
    }
    return null;
  }
}
