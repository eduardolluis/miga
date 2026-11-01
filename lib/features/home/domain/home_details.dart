import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/groceries/domain/grocery_purchase.dart';
import 'package:miga/features/pantry/domain/pantry_item.dart';
import 'package:miga/features/profile/domain/household_preferences.dart';

class HomeDetails {
  const HomeDetails({
    this.budgets = const {},
    this.groceries = const [],
    this.purchases = const [],
    this.preferences = const HouseholdPreferences(),
    this.pantry = const [],
    this.favorites = const {},
    this.servings = const {},
    this.syncGroceries = false,
    this.ingredientPrices = const {},
  });

  final Map<String, WeeklyBudget> budgets;
  final List<GroceryItem> groceries;
  final List<GroceryPurchase> purchases;
  final HouseholdPreferences preferences;
  final List<PantryItem> pantry;
  final Set<String> favorites;
  final Map<String, int> servings;
  final bool syncGroceries;
  // Price per kg, liter or piece in the active currency, entered by the user.
  final Map<String, int> ingredientPrices;

  HomeDetails copyWith({
    Map<String, WeeklyBudget>? budgets,
    List<GroceryItem>? groceries,
    List<GroceryPurchase>? purchases,
    HouseholdPreferences? preferences,
    List<PantryItem>? pantry,
    Set<String>? favorites,
    Map<String, int>? servings,
    bool? syncGroceries,
    Map<String, int>? ingredientPrices,
  }) => HomeDetails(
    budgets: budgets ?? this.budgets,
    groceries: groceries ?? this.groceries,
    purchases: purchases ?? this.purchases,
    preferences: preferences ?? this.preferences,
    pantry: pantry ?? this.pantry,
    favorites: favorites ?? this.favorites,
    servings: servings ?? this.servings,
    syncGroceries: syncGroceries ?? this.syncGroceries,
    ingredientPrices: ingredientPrices ?? this.ingredientPrices,
  );

  HomeDetails withBudget(String week, WeeklyBudget budget) =>
      copyWith(budgets: {...budgets, week: budget});

  HomeDetails withGroceries(List<GroceryItem> items) =>
      copyWith(groceries: items);

  Map<String, Object> toJson() => {
    'budgets': budgets.map((key, value) => MapEntry(key, value.toJson())),
    'groceries': groceries.map((item) => item.toJson()).toList(),
    'purchases': purchases.map((purchase) => purchase.toJson()).toList(),
    'preferences': preferences.toJson(),
    'pantry': pantry.map((item) => item.toJson()).toList(),
    'favorites': favorites.toList(),
    'servings': servings,
    'syncGroceries': syncGroceries,
    'ingredientPrices': ingredientPrices,
  };

  factory HomeDetails.fromJson(Map<String, dynamic> json) => HomeDetails(
    purchases: (json['purchases'] as List? ?? [])
        .map((item) => GroceryPurchase.fromJson(item as Map<String, dynamic>))
        .toList(),
    budgets: ((json['budgets'] as Map<String, dynamic>?) ?? {}).map(
      (key, value) =>
          MapEntry(key, WeeklyBudget.fromJson(value as Map<String, dynamic>)),
    ),
    groceries: (json['groceries'] as List<dynamic>? ?? [])
        .map((item) => GroceryItem.fromJson(item as Map<String, dynamic>))
        .toList(),
    preferences: HouseholdPreferences.fromJson(
      json['preferences'] as Map<String, dynamic>? ?? {},
    ),
    pantry: (json['pantry'] as List? ?? [])
        .map((e) => PantryItem.fromJson(e as Map<String, dynamic>))
        .whereType<PantryItem>()
        .toList(),
    favorites: (json['favorites'] as List? ?? []).whereType<String>().toSet(),
    servings: (json['servings'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, (v as num).toInt().clamp(1, 24)),
    ),
    syncGroceries: json['syncGroceries'] == true,
    ingredientPrices: (json['ingredientPrices'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toInt().clamp(0, 999999999))),
  );
}
