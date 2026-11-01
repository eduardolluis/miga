import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/profile/domain/household_preferences.dart';
import 'package:miga/features/recipes/data/recipe_catalog.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';

void main() {
  final recipes = {for (final recipe in RecipeCatalog.all) recipe.id: recipe};

  test('Vegetarian excludes meat and fish, allows legumes and egg', () {
    const p = HouseholdPreferences(restrictions: {DietaryRestriction.vegetarian});
    expect(p.allows(recipes['chicken-rice']!), isFalse);
    expect(p.allows(recipes['lemon-salmon']!), isFalse);
    expect(p.allows(recipes['chickpea-salad']!), isTrue);
    expect(p.allows(recipes['sweet-potato-egg']!), isTrue);
  });

  test('Vegan excludes meat, dairy, eggs and fish', () {
    const p = HouseholdPreferences(restrictions: {DietaryRestriction.vegan});
    expect(p.allows(recipes['avocado-toast']!), isFalse);
    expect(p.allows(recipes['yogurt-fruit']!), isFalse);
    expect(p.allows(recipes['banana-oats']!), isFalse); // ambiguous milk
    expect(p.allows(recipes['chickpea-salad']!), isTrue);
  });

  test('Gluten and nut restrictions conservatively block uncertain staples', () {
    const gluten = HouseholdPreferences(restrictions: {DietaryRestriction.glutenFree});
    const nuts = HouseholdPreferences(restrictions: {DietaryRestriction.nutFree});
    expect(gluten.allows(recipes['banana-oats']!), isFalse); // oats
    expect(gluten.allows(recipes['yogurt-fruit']!), isFalse); // granola
    expect(gluten.allows(recipes['avocado-toast']!), isFalse); // bread
    expect(gluten.allows(recipes['tomato-pasta']!), isFalse);
    expect(nuts.allows(recipes['banana-oats']!), isFalse); // walnuts
    expect(nuts.allows(recipes['yogurt-fruit']!), isFalse); // uncertain granola
  });

  test('Independent food restrictions and dislikes are cumulative', () {
    const p = HouseholdPreferences(
      restrictions: {DietaryRestriction.fishFree, DietaryRestriction.eggFree},
      disliked: {RecipeIngredient.avocado},
    );
    expect(p.allows(recipes['lemon-salmon']!), isFalse);
    expect(p.allows(recipes['sweet-potato-egg']!), isFalse);
    expect(p.allows(recipes['chickpea-salad']!), isFalse);
    expect(p.allows(recipes['lentil-soup']!), isTrue);
  });

  test('New region choices survive JSON and legacy settings survive', () {
    const p = HouseholdPreferences(country: 'MX', currency: 'MXN', members: 5,
      restrictions: {DietaryRestriction.dairyFree});
    final restored = HouseholdPreferences.fromJson(p.toJson());
    expect(restored.country, 'MX');
    expect(restored.currency, 'MXN');
    expect(restored.members, 5);
    expect(restored.restrictions, contains(DietaryRestriction.dairyFree));
    expect(HouseholdPreferences.fromJson({'country': 'US'}).currency, 'USD');
    expect(HouseholdPreferences.fromJson({}).currency, 'DOP');
    expect(HouseholdPreferences.fromJson({'country': 'XX', 'currency': 'XYZ'}).country, 'DO');
  });
}
