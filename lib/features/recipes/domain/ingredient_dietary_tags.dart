import 'package:miga/features/recipes/domain/recipe_ingredient.dart';

/// Conservative ingredient classification for recipe DISCOVERY only.
/// A tag can mean the ingredient definitely contains an allergen OR that its
/// generic name cannot guarantee the allergen is absent (e.g. granola).
/// Packaging, substitutions, cross-contact and preparation still require a
/// separate user check. Never describe this as an allergy-safety certification.
enum IngredientDietaryTag { meat, fish, dairy, eggs, gluten, treeNuts }

extension IngredientDietaryClassification on RecipeIngredient {
  Set<IngredientDietaryTag> get dietaryTags => switch (this) {
    RecipeIngredient.chicken => const {IngredientDietaryTag.meat},
    RecipeIngredient.salmon => const {IngredientDietaryTag.fish},
    RecipeIngredient.eggs => const {IngredientDietaryTag.eggs},
    RecipeIngredient.yogurt ||
    RecipeIngredient.cheese => const {IngredientDietaryTag.dairy},
    // "Milk / plant milk" is not guaranteed dairy free without a choice.
    RecipeIngredient.milk => const {IngredientDietaryTag.dairy},
    RecipeIngredient.walnuts => const {IngredientDietaryTag.treeNuts},
    RecipeIngredient.bread ||
    RecipeIngredient.pasta => const {IngredientDietaryTag.gluten},
    // Generic oats/granola do not guarantee gluten-free certification;
    // granola can also contain nuts. Treat both conservatively.
    RecipeIngredient.oats => const {IngredientDietaryTag.gluten},
    RecipeIngredient.granola => const {
      IngredientDietaryTag.gluten,
      IngredientDietaryTag.treeNuts,
    },
    // All remaining catalogue ingredients are whole foods or clearly named
    // single ingredients. Product labels must still be checked.
    RecipeIngredient.banana ||
    RecipeIngredient.cinnamon ||
    RecipeIngredient.avocado ||
    RecipeIngredient.tomatoes ||
    RecipeIngredient.oliveOil ||
    RecipeIngredient.salt ||
    RecipeIngredient.pepper ||
    RecipeIngredient.mango ||
    RecipeIngredient.strawberries ||
    RecipeIngredient.potatoes ||
    RecipeIngredient.broccoli ||
    RecipeIngredient.lemon ||
    RecipeIngredient.herbs ||
    RecipeIngredient.rice ||
    RecipeIngredient.carrot ||
    RecipeIngredient.garlic ||
    RecipeIngredient.chickpeas ||
    RecipeIngredient.cucumber ||
    RecipeIngredient.onion ||
    RecipeIngredient.basil ||
    RecipeIngredient.sweetPotato ||
    RecipeIngredient.spinach ||
    RecipeIngredient.lentils ||
    RecipeIngredient.celery ||
    RecipeIngredient.vegetableStock => const {},
  };
}
