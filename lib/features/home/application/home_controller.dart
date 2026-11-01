import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:miga/core/region/supported_regions.dart';

import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/groceries/application/plan_groceries.dart';
import 'package:miga/features/meal_plan/domain/planned_recipe.dart';
import 'package:miga/features/meal_plan/domain/plan_estimate.dart';
import 'package:miga/features/pantry/domain/pantry_item.dart';
import 'package:miga/features/profile/domain/household_preferences.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/groceries/domain/grocery_purchase.dart';
import 'package:miga/features/home/domain/home_details.dart';
import 'package:miga/features/home/domain/home_details_store.dart';
import 'package:miga/features/meal_plan/domain/meal_plan_store.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/recipes/data/recipe_repository.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    required DateTime today,
    required this.planStore,
    required this.detailsStore,
    this.costEstimator,
    RecipeRepository? recipeRepository,
  }) : recipes = recipeRepository ?? RecipeRepository.memory(const []),
       _now = today,
       selectedSlot = MealSlot.forTime(today),
       selectedDate = DateTime(today.year, today.month, today.day) {
    recipes.addListener(_catalogChanged);
  }
  final RecipeRepository recipes;
  int _catalogRevision = -1;
  void _catalogChanged() {
    if (_catalogRevision != recipes.revision) {
      _catalogRevision = recipes.revision;
      _costs.clear();
      _priceRevision++;
      if (!loading) unawaited(refreshPrices());
    }
    _emit();
  }

  Recipe? resolveMeal(String? value) => PlannedRecipe.parse(
    value,
    recipes: recipes.known,
  )?.resolve(recipes.known);

  DateTime _now;
  DateTime get now => _now;
  DateTime get today => DateTime(_now.year, _now.month, _now.day);
  final MealPlanStore planStore;
  final HomeDetailsStore detailsStore;
  final RecipeCostEstimator? costEstimator;
  final Map<String, RecipeCost> _costs = {};
  // Favoriting is a lightweight action: never trigger the global saving UI.
  Future<void> _favoriteWrites = Future<void>.value();
  int _pendingFavoriteWrites = 0;
  int _favoriteRevision = 0;
  Set<String> _confirmedFavorites = {};
  bool get favoriteSaving => _pendingFavoriteWrites > 0;
  int _priceRevision = 0;
  int get priceRevision => _priceRevision;
  bool pricing = false;
  String languageCode = 'es';
  Map<String, String>? _undoMeals;
  HomeDetails? _undoDetails;
  bool get canUndo => _undoMeals != null && canEdit;
  String get costCurrency => preferences.currency;
  bool get budgetCurrencyMatches =>
      budget == null || budget!.currency == costCurrency;
  HouseholdPreferences get preferences => details.preferences;
  Set<RecipeIngredient> get availableIngredients =>
      details.pantry.map((p) => p.ingredient).toSet();
  Map<String, String> get meals => Map.unmodifiable(_meals);
  void setLanguage(String value) {
    languageCode = value;
  }

  Recipe? recipeFor(DateTime date, MealSlot slot) =>
      resolveMeal(_meals[slot.keyFor(date)]);
  Recipe portionFor(Recipe recipe) =>
      recipe.withServings(details.servings[recipe.id] ?? preferences.members);

  RecipeCost costFor(Recipe recipe) {
    final cached = costEstimator?.costFromCache(recipe);
    final base =
        cached != null && cached.ingredients.any((line) => line.offer != null)
        ? cached
        : _costs[recipe.id];
    return RecipeCost(recipe, [
      for (final amount in RecipeAmounts.forRecipe(recipe))
        _ingredientCost(amount, base),
    ]);
  }

  IngredientCost _ingredientCost(RecipeAmount amount, RecipeCost? base) {
    final manual = details
        .ingredientPrices['${preferences.currency}:${amount.ingredient.name}'];
    if (manual != null) {
      return IngredientCost(
        amount,
        cents:
            manual *
            (amount.amount / (amount.unit == CostUnit.pieces ? 1 : 1000))
                .ceil(),
        purchaseCount:
            (amount.amount / (amount.unit == CostUnit.pieces ? 1 : 1000))
                .ceil(),
      );
    }
    if (preferences.currency != 'DOP' || preferences.country != 'DO') {
      return IngredientCost(amount);
    }
    for (final line in base?.ingredients ?? <IngredientCost>[]) {
      if (line.amount.ingredient == amount.ingredient &&
          line.cents != null &&
          line.offer?.isStale == false) {
        return RecipeCostEstimator.purchaseCost(amount, line.offer!);
      }
    }
    return IngredientCost(amount);
  }

  Future<void> refreshRecipePrices(Recipe recipe) async {
    if (costEstimator == null ||
        preferences.currency != 'DOP' ||
        preferences.country != 'DO') {
      return;
    }
    try {
      for (final cost in await costEstimator!.estimate([recipe])) {
        _costs[cost.recipe.id] = cost;
      }
      _priceRevision++;
      _emit();
    } catch (_) {
      // Missing catalog prices stay unknown; never invent a fallback amount.
    }
  }

  Future<void> refreshPrices() async {
    if (pricing ||
        costEstimator == null ||
        preferences.currency != 'DOP' ||
        preferences.country != 'DO') {
      return;
    }
    pricing = true;
    _emit();
    try {
      for (final cost in await costEstimator!.estimate(
        recipes.all,
        onProgress: () {
          _priceRevision++;
          _emit();
        },
      )) {
        _costs[cost.recipe.id] = cost;
      }
    } catch (_) {
      // Unknown prices stay explicitly incomplete and remain editable offline.
    } finally {
      pricing = false;
      _priceRevision++;
      _emit();
    }
  }

  PlanEstimate estimateFor([DateTime? date]) {
    final dates = date == null ? week : [date];
    var subtotal = 0, priced = 0, total = 0;
    for (final day in dates) {
      for (final slot in MealSlot.values) {
        if (_meals[slot.keyFor(day)] == null) continue;
        total++;
        final recipe = recipeFor(day, slot);
        if (recipe == null) continue;
        final cost = costFor(recipe);
        subtotal += cost.subtotalCents;
        if (cost.complete) priced++;
      }
    }
    return PlanEstimate(
      subtotalCents: subtotal,
      pricedMeals: priced,
      totalMeals: total,
    );
  }

  List<Recipe> recommendations(MealSlot slot) {
    final recommendations = recipes
        .forSlot(slot)
        .where(preferences.allows)
        .map(portionFor)
        .toList();
    final allowance = budget == null || !budgetCurrencyMatches
        ? null
        : mealAllowanceCents(budget!, now);
    recommendations.sort((a, b) {
      final ac = costFor(a), bc = costFor(b);
      if (allowance != null) {
        final fit = (bc.fits(allowance) ? 1 : 0).compareTo(
          ac.fits(allowance) ? 1 : 0,
        );
        if (fit != 0) return fit;
      }
      final pantry = b
          .matchingIngredients(availableIngredients)
          .compareTo(a.matchingIngredients(availableIngredients));
      if (pantry != 0) return pantry;
      final favorite = (details.favorites.contains(b.id) ? 1 : 0).compareTo(
        details.favorites.contains(a.id) ? 1 : 0,
      );
      return favorite != 0 ? favorite : a.sortOrder.compareTo(b.sortOrder);
    });
    return recommendations;
  }

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

  String? mealFor(DateTime date, MealSlot slot) {
    final value = _meals[slot.keyFor(date)];
    return resolveMeal(value)?.contentFor(languageCode).title ??
        (value?.startsWith('@miga:') == true
            ? (languageCode == 'es'
                  ? 'Receta no disponible'
                  : 'Recipe unavailable')
            : value);
  }

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
      await recipes.initialize();
      final (meals, homeDetails) = detailsStore is HouseholdStateStore
          ? await (detailsStore as HouseholdStateStore).loadState()
          : (await planStore.load(), await detailsStore.load());
      _meals = meals;
      details = homeDetails;
      await costEstimator?.restorePrices();
      unawaited(refreshPrices());
    } catch (_) {
      loadFailed = true;
    } finally {
      loading = false;
      _emit();
    }
  }

  Future<bool> saveMeal(DateTime date, MealSlot slot, String meal) async {
    final next = Map<String, String>.of(_meals);
    final key = slot.keyFor(date);
    if (meal.trim().isEmpty) {
      next.remove(key);
    } else {
      next[key] = meal.trim();
    }
    return _commit(next, details);
  }

  Future<bool> saveRecipe(DateTime date, MealSlot slot, Recipe recipe) =>
      _commit({
        ..._meals,
        slot.keyFor(date): PlannedRecipe(recipe.id, recipe.servings).encode(),
      }, details);

  Future<bool> copyDayMeals(DateTime fromDate, DateTime toDate) async {
    final next = Map<String, String>.of(_meals);
    for (final slot in MealSlot.values) {
      final value = _meals[slot.keyFor(fromDate)];
      if (value != null) next[slot.keyFor(toDate)] = value;
    }
    return _commit(next, details);
  }

  Future<bool> transferMeal(
    DateTime fromDate,
    MealSlot fromSlot,
    List<(DateTime, MealSlot)> targets, {
    bool move = false,
  }) async {
    final value = _meals[fromSlot.keyFor(fromDate)];
    if (value == null || targets.isEmpty) return false;
    final next = Map<String, String>.of(_meals);
    if (move) next.remove(fromSlot.keyFor(fromDate));
    for (final (date, slot) in targets) {
      next[slot.keyFor(date)] = value;
    }
    return _commit(next, details);
  }

  List<GroceryItem> generateGroceriesFromPlannedMeals({
    List<GroceryItem>? existingItems,
    Set<RecipeIngredient> pantry = const {},
    String? languageCode,
    String? currency,
  }) => _groceries(
    _meals,
    details,
    existingItems: existingItems,
    excluded: pantry,
    language: languageCode,
    currency: currency,
  );

  List<GroceryItem> _groceries(
    Map<String, String> meals,
    HomeDetails source, {
    List<GroceryItem>? existingItems,
    Set<RecipeIngredient> excluded = const {},
    String? language,
    String? currency,
  }) => groceriesForPlan(
    recipes: [
      for (final day in week)
        for (final slot in MealSlot.values)
          if (resolveMeal(meals[slot.keyFor(day)]) case final Recipe recipe)
            recipe,
    ],
    existing: existingItems ?? source.groceries,
    pantry: source.pantry,
    excluded: excluded,
    language: language ?? languageCode,
    currency: currency ?? source.preferences.currency,
  );

  Future<bool> saveBudget(WeeklyBudget value) {
    if (!value.limit.isFinite ||
        !value.spent.isFinite ||
        value.limit <= 0 ||
        value.spent < 0 ||
        !SupportedRegions.validCurrency(value.currency)) {
      return Future.value(false);
    }
    return _commit(
      _meals,
      details
          .withBudget(_weekKey, value)
          .copyWith(
            preferences: preferences.copyWith(currency: value.currency),
          ),
    );
  }

  Future<bool> completeGroceries(
    List<GroceryItem> items, {
    int? paidTotalCents,
  }) {
    if (!canEdit ||
        items.isEmpty ||
        items.any((item) => !item.checked) ||
        (paidTotalCents != null && paidTotalCents < 0)) {
      return Future.value(false);
    }
    final totals = GroceryTotals(items, preferences.currency);
    final completedAt = DateTime.now();
    final purchase = GroceryPurchase(
      id: 'purchase-${completedAt.microsecondsSinceEpoch}',
      completedAt: completedAt,
      items: List.unmodifiable(items),
      currency: preferences.currency,
      estimatedTotalCents: totals.subtotalCents,
      missingPrices: totals.missing,
      paidTotalCents: paidTotalCents,
    );
    return _commit(
      _meals,
      details.copyWith(
        groceries: [],
        syncGroceries: false,
        purchases: [...details.purchases, purchase],
      ),
      regenerate: false,
    );
  }

  Future<bool> saveGroceries(List<GroceryItem> items) =>
      _commit(_meals, details.withGroceries(items), regenerate: false);
  Future<bool> setGrocerySync(bool value, {List<GroceryItem>? items}) =>
      _commit(
        _meals,
        details.copyWith(
          syncGroceries: value,
          groceries: items ?? details.groceries,
        ),
      );
  Future<bool> savePreferences(HouseholdPreferences value) =>
      _commit(_meals, details.copyWith(preferences: value));
  Future<bool> savePantry(List<PantryItem> value) =>
      _commit(_meals, details.copyWith(pantry: value));
  Future<bool> setIngredientAvailable(RecipeAmount amount, bool available) {
    final pantry = details.pantry
        .where((p) => p.ingredient != amount.ingredient)
        .toList();
    if (available) {
      final existing = details.pantry
          .where(
            (p) => p.ingredient == amount.ingredient && p.unit == amount.unit,
          )
          .firstOrNull;
      pantry.add(
        PantryItem(
          amount.ingredient,
          math.max(amount.amount, existing?.amount ?? 0),
          amount.unit,
        ),
      );
    }
    return savePantry(pantry);
  }

  Future<bool> saveServings(String id, int servings) => _commit(
    _meals,
    details.copyWith(servings: {...details.servings, id: servings}),
  );

  /// Update the heart immediately, then persist in tap order. A favorite does
  /// not affect the meal plan, grocery calculations or the global saving flag.
  Future<bool> toggleFavorite(String id) {
    if (!canEdit) return Future.value(false);
    if (_pendingFavoriteWrites == 0) {
      _confirmedFavorites = {...details.favorites};
    }
    final revision = ++_favoriteRevision;
    final previous = details;
    final favorites = {...previous.favorites};
    if (!favorites.add(id)) favorites.remove(id);
    final updated = previous.copyWith(favorites: favorites);
    details = updated;
    _pendingFavoriteWrites++;
    _emit();

    final save = _favoriteWrites.then((_) async {
      try {
        // Preserve newer edits to unrelated fields while serializing taps.
        final snapshot = details.copyWith(favorites: updated.favorites);
        if (detailsStore case final HouseholdStateStore atomic) {
          await atomic.saveState(Map<String, String>.of(_meals), snapshot);
        } else {
          await detailsStore.save(snapshot);
        }
        _confirmedFavorites = {...snapshot.favorites};
        return true;
      } catch (_) {
        // Only the newest tap may roll back to the last confirmed state.
        if (revision == _favoriteRevision) {
          details = details.copyWith(favorites: {..._confirmedFavorites});
          _emit();
        }
        return false;
      } finally {
        _pendingFavoriteWrites--;
      }
    });
    // The queue never rejects, even if a storage write fails.
    _favoriteWrites = save.then((_) {});
    return save;
  }

  Future<bool> savePrices(Map<String, int> prices) =>
      _commit(_meals, details.copyWith(ingredientPrices: prices));

  Future<bool> saveIngredientPrice(RecipeIngredient ingredient, int? cents) {
    final prices = {...details.ingredientPrices};
    final key = '${preferences.currency}:${ingredient.name}';
    if (cents == null) {
      prices.remove(key);
    } else {
      prices[key] = cents;
    }
    return _commit(_meals, details.copyWith(ingredientPrices: prices));
  }

  List<(DateTime, MealSlot)> get remainingPlanSlots => [
    for (final date in week)
      for (final slot in MealSlot.values)
        if (date.isAfter(today) ||
            (date == today && slot.index >= MealSlot.forTime(now).index))
          (date, slot),
  ];

  List<Recipe> cheaperAlternatives(Recipe recipe) {
    final current = costFor(recipe);
    if (!current.complete) return [];
    final choices = recipes
        .forSlot(recipe.slot)
        .where(preferences.allows)
        .where((r) => r.id != recipe.id)
        .map((r) => r.withServings(recipe.servings))
        .where((r) {
          final cost = costFor(r);
          return cost.complete && cost.subtotalCents < current.subtotalCents;
        })
        .toList();
    choices.sort(
      (a, b) => costFor(a).subtotalCents.compareTo(costFor(b).subtotalCents),
    );
    return choices;
  }

  Map<String, String> automaticPlan() {
    final next = Map<String, String>.of(_meals);
    if (budget == null || !budgetCurrencyMatches) return next;
    var committed = 0;
    for (final (day, slot) in remainingPlanSlots) {
      if (!next.containsKey(slot.keyFor(day))) continue;
      final recipe = recipeFor(day, slot);
      if (recipe == null || !costFor(recipe).complete) return next;
      committed += costFor(recipe).subtotalCents;
    }
    var remaining = math.max(
      0,
      ((budget!.limit - budget!.spent) * 100).floor() - committed,
    );
    final counts = <String, int>{};
    final empty = [
      for (final (day, slot) in remainingPlanSlots)
        if (!next.containsKey(slot.keyFor(day))) (day, slot),
    ];
    for (var index = 0; index < empty.length; index++) {
      final (date, slot) = empty[index];
      final options = recommendations(slot);
      final allowance = remaining ~/ (empty.length - index);
      options.removeWhere((r) => !costFor(r).fits(allowance));
      options.sort((a, b) => (counts[a.id] ?? 0).compareTo(counts[b.id] ?? 0));
      if (options.isEmpty) continue;
      final chosen = options.first;
      next[slot.keyFor(date)] = PlannedRecipe(
        chosen.id,
        chosen.servings,
      ).encode();
      counts[chosen.id] = (counts[chosen.id] ?? 0) + 1;
      remaining -= costFor(chosen).subtotalCents;
    }
    return next;
  }

  Future<bool> applyPlan(Map<String, String> value) =>
      _commit(value, details.copyWith(syncGroceries: true));
  Future<bool> undo() async {
    final meals = _undoMeals;
    final home = _undoDetails;
    if (meals == null || home == null) return false;
    final result = await _commit(
      meals,
      home,
      remember: false,
      regenerate: false,
    );
    if (result) {
      _undoMeals = null;
      _undoDetails = null;
      _emit();
    }
    return result;
  }

  Future<bool> _commit(
    Map<String, String> meals,
    HomeDetails next, {
    bool remember = true,
    bool regenerate = true,
  }) async {
    if (!canEdit) return false;
    if (regenerate && next.syncGroceries) {
      next = next.withGroceries(_groceries(meals, next));
    }
    final oldMeals = Map<String, String>.of(_meals);
    final oldDetails = details;
    final mealChange = !mapEquals(oldMeals, meals);
    saving = true;
    _emit();
    try {
      // Keep a normal save from racing a pending optimistic favorite write.
      await _favoriteWrites;
      if (detailsStore case final HouseholdStateStore atomic) {
        await atomic.saveState(meals, next);
      } else {
        if (mealChange) await planStore.save(meals);
        try {
          await detailsStore.save(next);
        } catch (_) {
          if (mealChange) await planStore.save(oldMeals);
          rethrow;
        }
      }
      if (remember) {
        _undoMeals = oldMeals;
        _undoDetails = oldDetails;
      }
      _meals = Map.of(meals);
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
    recipes.removeListener(_catalogChanged);
    super.dispose();
  }
}
