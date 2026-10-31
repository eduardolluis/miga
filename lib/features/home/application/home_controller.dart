import 'package:flutter/foundation.dart';

import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/home/domain/home_details.dart';
import 'package:miga/features/home/domain/home_details_store.dart';
import 'package:miga/features/meal_plan/domain/meal_plan_store.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    required DateTime today,
    required this.planStore,
    required this.detailsStore,
  }) : _now = today,
       selectedSlot = MealSlot.forTime(today),
       selectedDate = DateTime(today.year, today.month, today.day);

  DateTime _now;
  DateTime get now => _now;
  DateTime get today => DateTime(_now.year, _now.month, _now.day);
  final MealPlanStore planStore;
  final HomeDetailsStore detailsStore;
  DateTime selectedDate;
  MealSlot selectedSlot;
  bool _automaticSlot = true;
  bool get automaticSlot => _automaticSlot;
  Map<String, String> _meals = {};
  HomeDetails details = const HomeDetails();
  bool loading = true;
  bool loadFailed = false;
  bool saving = false;
  bool _disposed = false;

  bool get canEdit => !loading && !loadFailed && !saving;
  DateTime get monday =>
      DateTime(today.year, today.month, today.day - today.weekday + 1);
  List<DateTime> get week => List.generate(
    7,
    (i) => DateTime(monday.year, monday.month, monday.day + i),
  );
  // Budget keys predate zero-padded meal dates; retain the existing format.
  String get _weekKey => '${monday.year}-${monday.month}-${monday.day}';
  WeeklyBudget? get budget => details.budgets[_weekKey];
  int get pendingGroceries =>
      details.groceries.where((item) => !item.checked).length;
  int get mealCount => week.fold(
    0,
    (count, date) =>
        count +
        MealSlot.values.where((slot) => mealFor(date, slot) != null).length,
  );

  String? mealFor(DateTime date, MealSlot slot) => _meals[slot.keyFor(date)];
  bool hasMeals(DateTime date) =>
      MealSlot.values.any((slot) => mealFor(date, slot) != null);

  void selectDate(DateTime date) {
    selectedDate = date;
    _emit();
  }

  void selectSlot(MealSlot slot) {
    _automaticSlot = false;
    selectedSlot = slot;
    _emit();
  }

  void useCurrentSlot() {
    _automaticSlot = true;
    selectedSlot = MealSlot.forTime(_now);
    _emit();
  }

  void syncTime(DateTime time) {
    final previousDay = today;
    final previousHour = _now.hour;
    _now = time;
    if (previousDay != today) selectedDate = today;
    if (_automaticSlot) selectedSlot = MealSlot.forTime(time);
    if (previousDay != today || previousHour != time.hour) _emit();
  }

  Future<void> load() async {
    loading = true;
    loadFailed = false;
    _emit();
    try {
      final meals = await planStore.load();
      final homeDetails = await detailsStore.load();
      _meals = meals;
      details = homeDetails;
    } catch (_) {
      loadFailed = true;
    } finally {
      loading = false;
      _emit();
    }
  }

  Future<bool> saveMeal(DateTime date, MealSlot slot, String meal) async {
    if (!canEdit) return false;
    final next = Map<String, String>.of(_meals);
    final key = slot.keyFor(date);
    if (meal.isEmpty) {
      next.remove(key);
    } else {
      next[key] = meal;
    }
    saving = true;
    _emit();
    try {
      // Publish changes only after storage confirms the write.
      await planStore.save(next);
      _meals = next;
      return true;
    } catch (_) {
      return false;
    } finally {
      saving = false;
      _emit();
    }
  }

  Future<bool> saveBudget(WeeklyBudget budget) =>
      _saveDetails(details.withBudget(_weekKey, budget));
  Future<bool> saveGroceries(List<GroceryItem> items) =>
      _saveDetails(details.withGroceries(items));

  Future<bool> _saveDetails(HomeDetails next) async {
    if (!canEdit) return false;
    saving = true;
    _emit();
    try {
      await detailsStore.save(next);
      details = next;
      return true;
    } catch (_) {
      return false;
    } finally {
      saving = false;
      _emit();
    }
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
