import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
import 'package:miga/features/recipes/domain/ingredient_dietary_tags.dart';
import 'package:miga/core/region/supported_regions.dart';

enum DietaryRestriction {
  vegetarian,
  vegan,
  dairyFree,
  glutenFree,
  nutFree,
  eggFree,
  fishFree,
}

class HouseholdPreferences {
  const HouseholdPreferences({
    this.country = 'DO',
    this.currency = 'DOP',
    this.language,
    this.members = 2,
    this.restrictions = const {},
    this.disliked = const {},
  });
  final String country;
  final String currency;
  final String? language;
  final int members;
  final Set<DietaryRestriction> restrictions;
  final Set<RecipeIngredient> disliked;
  HouseholdPreferences copyWith({String? currency, String? country}) =>
      HouseholdPreferences(
        country: country ?? this.country,
        currency: currency ?? this.currency,
        language: language,
        members: members,
        restrictions: restrictions,
        disliked: disliked,
      );

  /// Filters recommendations conservatively. NOT a guarantee against allergy
  /// exposure: packaged ingredients, substitutions and cross-contact still
  /// have to be checked by the person preparing the meal.
  bool allows(Recipe recipe) {
    final ingredients = <RecipeIngredient>{
      ...recipe.ingredients,
      ...RecipeAmounts.forRecipe(recipe).map((a) => a.ingredient),
    };
    if (ingredients.any(disliked.contains)) return false;
    final tags = ingredients.expand((i) => i.dietaryTags).toSet();
    for (final restriction in restrictions) {
      final blocked = switch (restriction) {
        DietaryRestriction.vegetarian => const {
          IngredientDietaryTag.meat,
          IngredientDietaryTag.fish,
        },
        DietaryRestriction.vegan => const {
          IngredientDietaryTag.meat,
          IngredientDietaryTag.fish,
          IngredientDietaryTag.dairy,
          IngredientDietaryTag.eggs,
        },
        DietaryRestriction.dairyFree => const {IngredientDietaryTag.dairy},
        DietaryRestriction.glutenFree => const {IngredientDietaryTag.gluten},
        DietaryRestriction.nutFree => const {
          IngredientDietaryTag.treeNuts,
          IngredientDietaryTag.peanuts,
        },
        DietaryRestriction.eggFree => const {IngredientDietaryTag.eggs},
        DietaryRestriction.fishFree => const {IngredientDietaryTag.fish},
      };
      if (tags.any(blocked.contains)) return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
    'country': country,
    'currency': currency,
    'language': language,
    'members': members,
    'restrictions': restrictions.map((r) => r.name).toList(),
    'disliked': disliked.map((i) => i.name).toList(),
  };

  factory HouseholdPreferences.fromJson(
    Map<String, dynamic> json,
  ) => HouseholdPreferences(
    country: SupportedRegions.forCountry(json['country'] as String?)
        .countryCode,
    currency: SupportedRegions.validCurrency(json['currency'] as String? ?? '')
        ? json['currency'] as String
        : SupportedRegions.forCountry(json['country'] as String?).currencyCode,
    language: ['es', 'en'].contains(json['language'])
        ? json['language'] as String
        : null,
    members: ((json['members'] as num?)?.toInt() ?? 2).clamp(1, 12),
    restrictions: DietaryRestriction.values
        .where((r) => (json['restrictions'] as List? ?? []).contains(r.name))
        .toSet(),
    disliked: RecipeIngredient.values
        .where((i) => (json['disliked'] as List? ?? []).contains(i.name))
        .toSet(),
  );
}
