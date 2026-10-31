import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:miga/features/meal_plan/domain/meal_plan_store.dart';

/// Plans stay on this device, with a separate key for each account.
class LocalMealPlanStore implements MealPlanStore {
  LocalMealPlanStore(String userId) : _key = 'miga.meals.v1.$userId';

  final String _key;

  @override
  Future<Map<String, String>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_key);
    if (encoded == null) return {};
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic> ||
        decoded.values.any((value) => value is! String)) {
      throw const FormatException('Invalid meal plan');
    }
    return decoded.cast<String, String>();
  }

  @override
  Future<void> save(Map<String, String> meals) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(_key, jsonEncode(meals))) {
      throw StateError('Meal plan could not be saved');
    }
  }
}
