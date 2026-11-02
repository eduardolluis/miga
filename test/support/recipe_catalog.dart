import 'dart:convert';
import 'dart:io';

import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/recipes/data/recipe_repository.dart';

/// Explicit fixtures. Production never bundles or reads this manifest.
abstract final class RecipeCatalog {
  static final List<Recipe> all = [
    for (final json
        in (jsonDecode(File('supabase/catalog/recipes.json').readAsStringSync())
                as Map<String, dynamic>)['recipes']
            as List)
      Recipe.fromJson(
        json as Map<String, dynamic>,
        imageBaseUrl: 'https://example.test/storage/v1/object/public/recipe-photos/',
      ),
  ];
  static List<Recipe> forSlot(MealSlot slot) =>
      all.where((r) => r.slot == slot).toList();
  static RecipeRepository repository() => RecipeRepository.memory(all);
}
