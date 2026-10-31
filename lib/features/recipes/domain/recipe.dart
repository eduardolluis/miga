import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';

class RecipeNutrition {
  const RecipeNutrition({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    this.fatGrams,
  });
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int? fatGrams;

  RecipeNutrition scaled(double factor) => RecipeNutrition(
    calories: (calories * factor).round(),
    proteinGrams: (proteinGrams * factor).round(),
    carbsGrams: (carbsGrams * factor).round(),
    fatGrams: fatGrams == null ? null : (fatGrams! * factor).round(),
  );
}

class RecipeContent {
  const RecipeContent({
    required this.title,
    required this.description,
    required this.ingredients,
    required this.steps,
  });
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
}

class Recipe {
  const Recipe({
    required this.id,
    required this.ingredients,
    required this.slot,
    required this.minutes,
    required this.servings,
    required this.imageIndex,
    required this.es,
    required this.en,
    this.nutrition,
  });
  final String id;
  final Set<RecipeIngredient> ingredients;
  final RecipeNutrition? nutrition;

  int matchingIngredients(Set<RecipeIngredient> available) =>
      ingredients.intersection(available).length;
  final MealSlot slot;
  final int minutes;
  final int servings;
  final int imageIndex;
  final RecipeContent es;
  final RecipeContent en;

  RecipeContent contentFor(String languageCode) =>
      languageCode == 'es' ? es : en;

  Recipe withServings(int value) {
    if (value < 1 || value > 24) throw ArgumentError.value(value, 'servings');
    return Recipe(
      id: id,
      ingredients: ingredients,
      slot: slot,
      minutes: minutes,
      servings: value,
      imageIndex: imageIndex,
      es: es,
      en: en,
      nutrition: nutrition,
    );
  }
}
