import 'package:miga/features/meal_plan/domain/meal_slot.dart';

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
    required this.slot,
    required this.minutes,
    required this.servings,
    required this.imageIndex,
    required this.es,
    required this.en,
  });
  final String id;
  final MealSlot slot;
  final int minutes;
  final int servings;
  final int imageIndex;
  final RecipeContent es;
  final RecipeContent en;

  RecipeContent contentFor(String languageCode) =>
      languageCode == 'es' ? es : en;
}
