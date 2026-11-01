import 'package:miga/features/recipes/domain/recipe_ingredient.dart';

abstract final class GroceryProduct {
  static String name(String raw) => raw
      .trim()
      .replaceFirst(
        RegExp(
          r'^\d+(?:[.,]\d+)?\s*(?:(?:g|gr|grams?|kg|ml|l|medium|large|small|cups?|tablespoons?|teaspoons?|tazas?|cucharadas?|cucharaditas?|medianas?|grandes?|pequeñas?)\b\s*)*',
          caseSensitive: false,
        ),
        '',
      )
      .replaceFirst(
        RegExp(r'\s+(?:to taste|al gusto)$', caseSensitive: false),
        '',
      )
      .trim();

  static RecipeIngredient? ingredient(String raw) {
    final value = name(raw).toLowerCase();
    for (final ingredient in RecipeIngredient.values) {
      if (value == ingredient.en.toLowerCase() ||
          value == ingredient.es.toLowerCase()) {
        return ingredient;
      }
    }
    return const {
      'egg': RecipeIngredient.eggs,
      'huevo': RecipeIngredient.eggs,
      'sweet potatoes': RecipeIngredient.sweetPotato,
      'milk': RecipeIngredient.milk,
      'plant milk': RecipeIngredient.milk,
      'leche': RecipeIngredient.milk,
      'guineo': RecipeIngredient.banana,
      'tomato': RecipeIngredient.tomatoes,
      'tomate': RecipeIngredient.tomatoes,
      'potato': RecipeIngredient.potatoes,
      'papa': RecipeIngredient.potatoes,
    }[value];
  }
}
