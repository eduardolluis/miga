abstract interface class MealPlanStore {
  Future<Map<String, String>> load();
  Future<void> save(Map<String, String> meals);
}
