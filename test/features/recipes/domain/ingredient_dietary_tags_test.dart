import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/recipes/domain/ingredient_dietary_tags.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';

void main() {
  test('Dietary tagging covers every existing ingredient', () {
    for (final ingredient in RecipeIngredient.values) {
      expect(ingredient.dietaryTags, isA<Set<IngredientDietaryTag>>());
    }
    expect(
      RecipeIngredient.salmon.dietaryTags,
      contains(IngredientDietaryTag.fish),
    );
    expect(
      RecipeIngredient.granola.dietaryTags,
      containsAll([IngredientDietaryTag.gluten, IngredientDietaryTag.treeNuts]),
    );
  });
}
