import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/profile/domain/household_preferences.dart';
import 'package:miga/features/recipes/data/recipe_catalog.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';

void main() {
  test('54 recipes: 18 each for breakfast lunch and dinner', () {
    expect(RecipeCatalog.all, hasLength(54));
    for (final slot in MealSlot.values) {
      expect(RecipeCatalog.forSlot(slot), hasLength(18));
    }
    expect(RecipeCatalog.all.map((r) => r.id).toSet(), hasLength(54));
  });

  test('all recipes contain bilingual instructions and matching cost ingredients', () {
    for (final recipe in RecipeCatalog.all) {
      expect(recipe.minutes, greaterThan(0), reason: recipe.id);
      expect(recipe.servings, 2, reason: recipe.id);
      expect(recipe.es.title.trim(), isNotEmpty, reason: recipe.id);
      expect(recipe.en.title.trim(), isNotEmpty, reason: recipe.id);
      expect(recipe.es.steps, isNotEmpty, reason: recipe.id);
      expect(recipe.en.steps, isNotEmpty, reason: recipe.id);
      final amounts = RecipeAmounts.forRecipe(recipe);
      expect(amounts, isNotEmpty, reason: recipe.id);
      expect(amounts.every((a) => a.amount > 0), isTrue, reason: recipe.id);
      expect(amounts.map((a) => a.ingredient).toSet(), recipe.ingredients,
          reason: recipe.id);
      expect(recipe.nutrition, isNotNull, reason: recipe.id);
    }
  });

  test('new recipes use unique image indexes outside the original atlas', () {
    expect(RecipeCatalog.all.take(9).every((r) => r.imageIndex < 9), isTrue);
    expect(RecipeCatalog.all.skip(9).every((r) => r.imageIndex >= 9), isTrue);
  });

  test('dietary filters exclude beef, tuna, peanuts, tofu and wheat as needed', () {
    final byId = {for (final recipe in RecipeCatalog.all) recipe.id: recipe};
    bool allows(String id, DietaryRestriction restriction) =>
        HouseholdPreferences(restrictions: {restriction}).allows(byId[id]!);
    expect(allows('beef-pepper-rice', DietaryRestriction.vegetarian), isFalse);
    expect(allows('tuna-chickpea-salad', DietaryRestriction.fishFree), isFalse);
    expect(allows('peanut-banana-toast', DietaryRestriction.nutFree), isFalse);
    expect(allows('vegetable-quesadillas', DietaryRestriction.glutenFree), isFalse);
    expect(allows('tofu-broccoli-rice', DietaryRestriction.vegan), isTrue);
    expect(HouseholdPreferences(disliked: {RecipeIngredient.tuna})
        .allows(byId['tuna-potato-salad']!), isFalse);
  });
}
