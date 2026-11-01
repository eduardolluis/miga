import 'dart:async';
import 'dart:math';

import 'package:miga/features/budget/presentation/savings_page.dart';
import 'package:miga/features/groceries/presentation/shared_grocery_page.dart';
import 'package:miga/features/groceries/presentation/groceries_tab_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miga/features/sync/data/cloud_sync.dart';
import 'package:miga/features/pro/application/store_subscription_service.dart';
import 'package:miga/features/privacy/presentation/privacy_page.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/budget/presentation/sheets/ingredient_prices_sheet.dart';
import 'package:miga/features/budget/presentation/spending_page.dart';
import 'package:miga/features/pantry/presentation/pantry_sheet.dart';
import 'package:miga/features/profile/presentation/preferences_sheet.dart';
import 'package:miga/features/meal_plan/presentation/sheets/plan_recipe_sheet.dart';

import 'package:flutter/material.dart';
import 'package:miga/features/budget/data/recipe_price_store.dart';
import 'package:flutter/services.dart';

import 'package:miga/app/navigation/app_tab.dart';
import 'package:miga/app/navigation/widgets/app_bottom_navigation.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/core/theme/app_theme.dart';
import 'package:miga/core/ui/deferred_progress.dart';
import 'package:miga/core/ui/miga_skeleton.dart';
import 'package:miga/app/navigation/widgets/app_page_skeleton.dart';
import 'package:miga/core/ui/miga_notice.dart';
import 'package:miga/features/notifications/presentation/notifications_page.dart';
import 'package:miga/features/pantry/presentation/pantry_empty_sheet.dart';
import 'package:miga/features/groceries/presentation/sheets/grocery_checkout_sheet.dart';
import 'package:miga/features/auth/domain/auth_service.dart';
import 'package:miga/features/budget/presentation/sheets/budget_editor_sheet.dart';
import 'package:miga/features/groceries/presentation/sheets/grocery_list_sheet.dart';
import 'package:miga/features/home/application/home_controller.dart';
import 'package:miga/features/home/application/surprise_quota_service.dart';
import 'package:miga/features/recipes/data/recipe_repository.dart';
import 'package:miga/features/home/data/local_home_details_store.dart';
import 'package:miga/features/home/domain/home_details_store.dart';
import 'package:miga/features/home/presentation/home_screen.dart';
import 'package:miga/features/meal_plan/data/local_meal_plan_store.dart';
import 'package:miga/features/meal_plan/domain/meal_plan_store.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/meal_plan/presentation/meal_slot_presentation.dart';
import 'package:miga/features/meal_plan/presentation/meal_plan_page.dart';
import 'package:miga/features/meal_plan/presentation/sheets/meal_editor_sheet.dart';
import 'package:miga/features/profile/presentation/profile_page.dart';
import 'package:miga/features/pro/presentation/pro_page.dart';
import 'package:miga/features/recipes/presentation/recipes_page.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/presentation/sheets/recipe_details_sheet.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/stores/data/nearby_stores.dart';
import 'package:miga/l10n/app_localizations.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.authService,
    this.planStore,
    this.detailsStore,
    this.today,
    this.openNearbyStores = NearbyStores.open,
    this.onLanguageChanged,
    this.client,
    this.enablePriceEstimates = false,
    this.recipeRepository,
  });

  final void Function(String?)? onLanguageChanged;
  final bool enablePriceEstimates;
  final RecipeRepository? recipeRepository;
  final SupabaseClient? client;
  final AuthService? authService;
  final MealPlanStore? planStore;
  final HomeDetailsStore? detailsStore;
  final DateTime? today;
  final Future<bool> Function(String languageCode) openNearbyStores;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final _tabAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 170),
    value: 1,
  );
  late final HomeController _controller;
  late final RecipeRepository _recipes;
  AppTab _tab = AppTab.home;
  int _budgetRecipeFilterRequest = 0;
  int _pantryRecipeFilterRequest = 0;
  late final SurpriseQuotaService _surpriseQuota;
  int _surpriseRemaining = 3;
  bool _surpriseBusy = false;
  String? _lastSurpriseRecipe;

  void _selectTab(AppTab tab) {
    final changed = tab != _tab;
    if (tab == AppTab.plan && _purchases?.active != true) {
      _openPro();
      return;
    }
    setState(() {
      _tab = tab;
      // The normal Recipes tab opens the catalog without retaining a
      // Home shortcut's budget/pantry filter.
      if (tab == AppTab.recipes) {
        _budgetRecipeFilterRequest = 0;
        _pantryRecipeFilterRequest = 0;
      }
    });
    if (changed && !MediaQuery.disableAnimationsOf(context)) {
      _tabAnimation.forward(from: 0);
    }
  }

  void _viewBudgetRecipes() {
    final hasBudget =
        _controller.budget != null && _controller.budgetCurrencyMatches;
    setState(() {
      _tab = AppTab.recipes;
      _pantryRecipeFilterRequest = 0;
      // Positive request activates Within budget; negative request opens the
      // regular catalog when no matching budget exists (no empty filter).
      _budgetRecipeFilterRequest = hasBudget
          ? _budgetRecipeFilterRequest.abs() + 1
          : -(_budgetRecipeFilterRequest.abs() + 1);
    });
  }

  bool _signingOut = false;
  Timer? _clockTimer, _syncTimer;
  CloudSync? _cloud;
  StoreSubscriptionService? _purchases;
  int _loadedCloudGeneration = 0;
  int _editorDepth = 0;
  bool _syncing = false, _deleting = false;

  @override
  void initState() {
    super.initState();
    _surpriseQuota = SurpriseQuotaService(client: widget.client);
    unawaited(_refreshSurpriseQuota());
    final userId = widget.authService?.session?.user.id ?? 'guest';
    if (widget.client != null &&
        widget.client!.auth.currentUser?.id == userId) {
      _cloud = CloudSync(widget.client!, userId)..addListener(_cloudChanged);
      _purchases = StoreSubscriptionService(widget.client!)
        ..addListener(_cloudChanged);
      unawaited(_purchases!.initialize());
    }
    final source = widget.client == null
        ? null
        : SupabaseRecipeSource(widget.client!);
    _recipes =
        widget.recipeRepository ??
        RecipeRepository(
          source: source,
          cache: source == null ? null : LocalRecipeCache(source.imageBaseUrl),
        );
    _controller = HomeController(
      recipeRepository: _recipes,
      today: widget.today ?? DateTime.now(),
      planStore:
          widget.planStore ??
          (_cloud == null
              ? LocalMealPlanStore(userId)
              : SyncedMealPlanStore(_cloud!)),
      detailsStore:
          widget.detailsStore ??
          (_cloud == null
              ? LocalHomeDetailsStore(userId)
              : SyncedHomeDetailsStore(_cloud!)),
      costEstimator: widget.enablePriceEstimates
          ? RecipeCostEstimator(priceStore: LocalRecipePriceStore())
          : null,
    );
    unawaited(
      _controller.load().then((_) {
        if (mounted) {
          widget.onLanguageChanged?.call(_controller.preferences.language);
          unawaited(_syncNow());
        }
      }),
    );
    WidgetsBinding.instance.addObserver(this);
    if (_cloud != null) {
      _syncTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _syncNow(),
      );
    }
    // A supplied date freezes the clock for tests and design previews.
    if (widget.today == null) {
      _clockTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _controller.syncTime(DateTime.now()),
      );
    }
  }

  @override
  void dispose() {
    _tabAnimation.dispose();
    _clockTimer?.cancel();
    _syncTimer?.cancel();
    _cloud?.removeListener(_cloudChanged);
    _cloud?.dispose();
    _purchases?.removeListener(_cloudChanged);
    _purchases?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    if (widget.recipeRepository == null) _recipes.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.today == null) {
      _controller.syncTime(DateTime.now());
      unawaited(_syncNow());
      unawaited(_recipes.refresh());
      unawaited(_purchases?.refreshEntitlement());
      unawaited(_refreshSurpriseQuota());
    }
  }

  String? get _userName {
    final user = widget.authService?.session?.user;
    for (final key in ['given_name', 'full_name', 'name']) {
      final value = user?.userMetadata?[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim().split(RegExp(r'\s+')).first;
      }
    }
    final email = user?.email;
    if (email == null || email.isEmpty) return null;
    final first = email.split('@').first.split(RegExp(r'[._-]')).first;
    return first.isEmpty
        ? null
        : '${first[0].toUpperCase()}${first.substring(1)}';
  }

  Future<T?> _editSession<T>(Future<T?> Function() action) async {
    _editorDepth++;
    try {
      return await action();
    } finally {
      _editorDepth--;
      if (_editorDepth == 0) Timer.run(() => _syncNow());
    }
  }

  Future<bool> _save(Future<bool> Function() action, {String? message}) async {
    if (!mounted) return false;
    if (_cloud != null && _cloud!.remoteGeneration != _loadedCloudGeneration) {
      final l = AppLocalizations.of(context)!;
      final keepLocal = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.syncTitle),
          content: Text(l.syncConflict),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.keepCloud),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.keepLocal),
            ),
          ],
        ),
      );
      if (!mounted) return false;
      await _controller.load();
      _loadedCloudGeneration = _cloud!.remoteGeneration;
      if (keepLocal != true || !mounted) return false;
    }
    final success = await action();
    if (!mounted) return success;
    if (success) {
      final l = AppLocalizations.of(context)!;
      showMigaNotice(
        context,
        message ?? l.savedSuccess,
        action: _controller.canUndo
            ? SnackBarAction(
                label: l.undoAction,
                onPressed: () => _save(_controller.undo),
              )
            : null,
      );
    } else {
      final l10n = AppLocalizations.of(context)!;
      showMigaNotice(
        context,
        l10n.homeSaveError,
        error: true,
        action: SnackBarAction(
          label: l10n.homeRetry,
          onPressed: () => _save(action),
        ),
      );
    }
    return success;
  }

  /// Favorites should feel like an instant toggle, not a full save workflow.
  void _toggleFavorite(String id) {
    unawaited(
      _controller.toggleFavorite(id).then((saved) {
        if (!saved && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.homeSaveError),
            ),
          );
        }
      }),
    );
  }

  Future<void> _editMeal(
    DateTime date,
    MealSlot slot, {
    String? suggestion,
  }) async {
    if (_requiresPro) {
      _openPro();
      return;
    }
    if (!_controller.canEdit) return;
    final planned = _controller.recipeFor(date, slot);
    if (planned != null && suggestion == null) {
      await _openRecipe(planned, plannedDate: date, plannedSlot: slot);
      return;
    }
    final result = await showMealEditor(
      context,
      date: date,
      slot: slot,
      meal: _controller.mealFor(date, slot),
      suggestion: suggestion,
    );
    if (!mounted || result == null) return;
    await _save(
      () => _controller.saveMeal(date, slot, result),
      message: result.isEmpty
          ? null
          : AppLocalizations.of(context)!.mealAddedSuccess,
    );
  }

  Future<void> _openRecipe(
    Recipe recipe, {
    DateTime? plannedDate,
    MealSlot? plannedSlot,
  }) async {
    if (!_controller.canEdit) return;
    final chosen = await _editSession(
      () => showRecipeDetails(
        context,
        plannedDate == null ? _controller.portionFor(recipe) : recipe,
        planLabel: plannedDate == null
            ? null
            : AppLocalizations.of(context)!.homeSave,
        pantry: _controller.details.pantry,
        onPantryChanged: (amount, available) async {
          final saved = await _controller.setIngredientAvailable(
            amount,
            available,
          );
          return saved ? _controller.details.pantry : null;
        },
        costFor: _controller.costFor,
        onRefreshPrices: _controller.refreshRecipePrices,
        manualPrices: _controller.details.ingredientPrices,
        budget: _controller.budget,
        currency: _controller.costCurrency,
        now: _controller.now,
        favorite: _controller.details.favorites.contains(recipe.id),
        onToggleFavorite: () => _controller.toggleFavorite(recipe.id),
        onServingsChanged: (servings) => plannedDate == null
            ? _controller.saveServings(recipe.id, servings)
            : _controller.saveRecipe(
                plannedDate,
                plannedSlot!,
                recipe.withServings(servings),
              ),
        onEditPrices: _editPrices,
        onAddAmounts: (amounts) => _addAmounts(recipe, amounts),
      ),
    );
    if (!mounted || chosen == null) return;
    if (plannedDate == null) {
      await _planRecipe(chosen);
    } else {
      await _save(
        () => _controller.saveRecipe(plannedDate, plannedSlot!, chosen),
      );
    }
  }

  Future<void> _editBudget() async {
    if (!_controller.canEdit) return;
    final budget = await _editSession(
      () => showBudgetEditor(context, _controller.budget),
    );
    if (!mounted || budget == null) return;
    await _save(() => _controller.saveBudget(budget));
  }

  Future<void> _openGroceries() async {
    if (!_controller.canEdit) return;
    var syncWithPlan = _controller.details.syncGroceries;
    final items = await _editSession(
      () => showGroceryList(
        context,
        _controller.details.groceries,
        syncWithPlan: syncWithPlan,
        allowEstimates: _controller.preferences.country == 'DO',
        isPro: !_requiresPro,
        onUpgrade: _openPro,
        onComplete: _completeGroceryPurchase,
        onSyncChanged: (value) => syncWithPlan = value,
        currency: _controller.preferences.currency,
        onGenerateFromPlan: (items) =>
            _controller.generateGroceriesFromPlannedMeals(
              existingItems: items,
              languageCode: Localizations.localeOf(context).languageCode,
              currency: _controller.preferences.currency,
            ),
      ),
    );
    if (!mounted || items == null) return;
    await _save(() => _controller.setGrocerySync(syncWithPlan, items: items));
  }

  Future<bool> _completeGroceryPurchase(List<GroceryItem> items) async {
    if (!_controller.canEdit) return false;
    final checkout = await showGroceryCheckout(
      context,
      items,
      _controller.preferences.currency,
    );
    if (!mounted || checkout == null) return false;
    return _save(
      () => _controller.completeGroceries(
        items,
        paidTotalCents: checkout.paidTotalCents,
      ),
      message: AppLocalizations.of(context)!.groceryCompleted,
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(
          data: AppTheme.household(Theme.of(context)),
          child: NotificationsPage(
            controller: _controller,
            onGroceries: () {
              Navigator.of(context).pop();
              _selectTab(AppTab.groceries);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _generateGroceryPlan() async {
    if (_requiresPro) {
      _openPro();
      return;
    }
    if (!_controller.canEdit) return;
    final items = _controller.generateGroceriesFromPlannedMeals(
      existingItems: _controller.details.groceries,
      languageCode: Localizations.localeOf(context).languageCode,
      currency: _controller.preferences.currency,
    );
    await _save(() => _controller.setGrocerySync(true, items: items));
    if (mounted) await _openGroceries();
  }

  Future<void> _compareGroceryPrices() async {
    if (_requiresPro) {
      _openPro();
      return;
    }
    if (!_controller.canEdit) return;
    if (_controller.details.groceries.isEmpty) {
      await _openGroceries();
      return;
    }
    final items = await compareGroceryItems(
      context,
      _controller.details.groceries,
    );
    if (!mounted || items == null) return;
    await _save(() => _controller.saveGroceries(items));
  }

  Future<bool> _addAmounts(Recipe recipe, List<RecipeAmount> amounts) async {
    final language = Localizations.localeOf(context).languageCode;
    final items = List<GroceryItem>.of(_controller.details.groceries);
    for (final amount in amounts) {
      final index = items.indexWhere(
        (item) => item.ingredientId == amount.ingredient.name,
      );
      final old = index < 0 ? null : items[index];
      final item = GroceryItem(
        amount.ingredient.label(language),
        checked: false,
        quantity: old?.quantity ?? 1,
        currency: _controller.preferences.currency,
        unitPriceCents: old?.unitPriceCents,
        offer: old?.offer,
        reference: old?.reference,
        isEstimated: old?.isEstimated ?? true,
        ingredientId: amount.ingredient.name,
        requiredAmount: (old?.requiredAmount ?? 0) + amount.amount,
        requiredUnit: amount.unit,
      );
      if (index < 0) {
        items.add(item);
      } else {
        items[index] = item;
      }
    }
    return _controller.saveGroceries(items);
  }

  Future<void> _planRecipe(Recipe recipe) async {
    if (_requiresPro) {
      _openPro();
      return;
    }
    if (!_controller.canEdit) return;
    final target = await showPlanRecipe(
      context,
      recipe: recipe,
      week: _controller.week,
      selectedDate: _controller.selectedDate,
      mealFor: _controller.mealFor,
    );
    if (!mounted || target == null) return;
    await _save(
      () => _controller.saveRecipe(
        target.$1,
        target.$2,
        recipe.withServings(target.$3),
      ),
      message: AppLocalizations.of(context)!.mealAddedSuccess,
    );
  }

  Future<void> _editPreferences() async {
    final value = await _editSession(
      () => showHouseholdPreferences(context, _controller.preferences),
    );
    if (!mounted || value == null) return;
    if (await _save(() => _controller.savePreferences(value)) && mounted) {
      widget.onLanguageChanged?.call(value.language);
    }
  }

  Future<void> _editPantry() async {
    final items = await _editSession(
      () => showPantry(context, _controller.details.pantry),
    );
    if (!mounted || items == null) return;
    await _save(() => _controller.savePantry(items));
  }

  Future<void> _editPrices() async {
    final prices = await _editSession(
      () => showIngredientPrices(
        context,
        _controller.preferences.currency,
        _controller.details.ingredientPrices,
      ),
    );
    if (!mounted || prices == null) return;
    await _save(() => _controller.savePrices(prices));
  }

  void _openSpending() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SpendingPage(controller: _controller),
    ),
  );

  // The Pro gate must work even before App Store products are configured.
  // The entitlement is checked against server-verified subscription state.
  bool get _requiresPro => _purchases?.active != true;

  Future<void> _refreshSurpriseQuota() async {
    try {
      final allowance = await _surpriseQuota.remaining();
      if (mounted) setState(() => _surpriseRemaining = allowance.remaining);
    } catch (_) {
      // A missing migration or network error must never reset the quota.
      // Consumption will fail closed and display a retry message.
    }
  }

  Future<void> _cookWithPantry() async {
    if (_controller.availableIngredients.isEmpty) {
      final add = await showPantryEmptySheet(context);
      if (!mounted || add != true) return;
      await _editPantry();
      if (!mounted || _controller.availableIngredients.isEmpty) return;
    }
    setState(() {
      _tab = AppTab.recipes;
      _budgetRecipeFilterRequest = 0;
      _pantryRecipeFilterRequest++;
    });
  }

  Future<void> _surpriseMe() async {
    if (_surpriseBusy || !_controller.canEdit) return;
    final recipes = _recipes.all.where(_controller.preferences.allows).toList();
    if (recipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recipes match your preferences.')),
      );
      return;
    }
    setState(() => _surpriseBusy = true);
    SurpriseAllowance? allowance;
    try {
      // Always consult the server for a signed-in account, even if local Pro
      // entitlement was not refreshed. A failed RPC cannot grant free uses.
      allowance = await _surpriseQuota.consume();
      if (!mounted) return;
      setState(() => _surpriseRemaining = allowance!.remaining);
    } catch (_) {
      if (!mounted) return;
      final spanish = Localizations.localeOf(context).languageCode == 'es';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            spanish
                ? 'No pudimos verificar tus usos. Intenta de nuevo.'
                : 'Could not verify your free uses. Please retry.',
          ),
        ),
      );
      return;
    } finally {
      if (mounted) setState(() => _surpriseBusy = false);
    }
    if (!mounted) return;
    if (!allowance.allowed) {
      _openPro();
      return;
    }
    final choices = recipes.where((r) => r.id != _lastSurpriseRecipe).toList();
    final pool = choices.isEmpty ? recipes : choices;
    final chosen = pool[Random().nextInt(pool.length)];
    _lastSurpriseRecipe = chosen.id;
    await _openRecipe(chosen);
  }

  void _openSavings() {
    if (_requiresPro) {
      _openPro();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavingsPage(
          controller: _controller,
          onReplace: (date, slot, recipe) async {
            await _save(() => _controller.saveRecipe(date, slot, recipe));
          },
        ),
      ),
    );
  }

  Future<void> _autoPlan() async {
    if (_requiresPro) {
      _openPro();
      return;
    }
    final l = AppLocalizations.of(context)!;
    if (_controller.budget == null) {
      await _editBudget();
      if (!mounted || _controller.budget == null) return;
    }
    final proposal = _controller.automaticPlan();
    final added = proposal.entries
        .where((e) => _controller.meals[e.key] != e.value)
        .toList();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.autoPlanPreview),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.autoPlanNote),
                const SizedBox(height: 12),
                if (proposal.length < _controller.week.length * 3)
                  Text(l.autoPlanMissing),
                for (final entry in added)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '${entry.key.split(':').first} · ${_controller.resolveMeal(entry.value)!.contentFor(l.localeName).title}',
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancelAction),
          ),
          FilledButton(
            onPressed: added.isEmpty
                ? null
                : () => Navigator.pop(context, true),
            child: Text(l.applyPlan),
          ),
        ],
      ),
    );
    if (!mounted || accepted != true) return;
    await _save(() => _controller.applyPlan(proposal));
  }

  Future<void> _transferMeal(
    DateTime from,
    MealSlot slot,
    String action,
  ) async {
    if (!_controller.canEdit) return;
    if (action == 'delete') {
      await _save(() => _controller.saveMeal(from, slot, ''));
      return;
    }
    final l = AppLocalizations.of(context)!;
    final chosen = <DateTime>{};
    var targetSlot = slot;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(
            action == 'move'
                ? l.moveMeal
                : action == 'repeat'
                ? l.repeatMeal
                : l.copyMeal,
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<MealSlot>(
                    initialValue: targetSlot,
                    items: [
                      for (final value in MealSlot.values)
                        DropdownMenuItem(
                          value: value,
                          child: Text(value.label(l)),
                        ),
                    ],
                    onChanged: (value) => update(() => targetSlot = value!),
                  ),
                  for (final day in _controller.week)
                    CheckboxListTile(
                      title: Text(
                        MaterialLocalizations.of(context).formatFullDate(day),
                      ),
                      value: chosen.contains(day),
                      onChanged: (value) => update(() {
                        if (action == 'move' || action == 'copy') {
                          chosen.clear();
                        }
                        if (value == true) chosen.add(day);
                      }),
                    ),
                  Text(l.overwriteWarning),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancelAction),
            ),
            FilledButton(
              onPressed: chosen.isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              child: Text(l.confirmAction),
            ),
          ],
        ),
      ),
    );
    if (!mounted || accepted != true) return;
    await _save(
      () => _controller.transferMeal(from, slot, [
        for (final date in chosen) (date, targetSlot),
      ], move: action == 'move'),
    );
  }

  Future<void> _chooseRecipe(DateTime date, MealSlot slot) async {
    if (_requiresPro) {
      _openPro();
      return;
    }
    final l = AppLocalizations.of(context)!;
    final choices = _controller.recommendations(slot);
    final recipe = await showDialog<Recipe>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l.chooseRecipe),
        children: [
          if (choices.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.recipeNoResults),
            ),
          for (final recipe in choices)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, recipe),
              child: Text(recipe.contentFor(l.localeName).title),
            ),
        ],
      ),
    );
    if (!mounted || recipe == null) return;
    await _save(
      () => _controller.saveRecipe(date, slot, recipe),
      message: l.mealAddedSuccess,
    );
  }

  Future<void> _openStores() async {
    try {
      final opened = await widget.openNearbyStores(
        Localizations.localeOf(context).languageCode,
      );
      if (opened) return;
    } catch (_) {
      // Keep the grocery list usable when an external maps app is unavailable.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.homeMapsUnavailable),
      ),
    );
  }

  void _openPro() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Theme(
          data: AppTheme.household(Theme.of(context)),
          child: ProPage(
            purchases: _purchases,
            onAutoPlan: _autoPlan,
            onPantry: _editPantry,
            onSpending: _openSpending,
          ),
        ),
      ),
    );
  }

  Future<void> _copyDay(DateTime fromDate) async {
    if (!_controller.canEdit) return;
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final targetDate = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.planCopyDayTo(dates.formatShortMonthDay(fromDate))),
        children: [
          for (final date in _controller.week)
            if (!DateUtils.isSameDay(date, fromDate))
              SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(date),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(dates.formatFullDate(date)),
                ),
              ),
        ],
      ),
    );
    if (!mounted || targetDate == null) return;
    await _save(
      () => _controller.copyDayMeals(fromDate, targetDate),
      message: l10n.planCopySuccess(dates.formatShortMonthDay(targetDate)),
    );
  }

  void _cloudChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _syncNow() async {
    if (_cloud == null ||
        _syncing ||
        _controller.saving ||
        _controller.favoriteSaving ||
        _editorDepth > 0 ||
        _deleting) {
      return;
    }
    _syncing = true;
    try {
      await _cloud!.sync();
      if (mounted &&
          _loadedCloudGeneration != _cloud!.remoteGeneration &&
          !_controller.saving &&
          _editorDepth == 0) {
        _loadedCloudGeneration = _cloud!.remoteGeneration;
        await _controller.load();
        if (mounted) {
          widget.onLanguageChanged?.call(_controller.preferences.language);
        }
      }
    } finally {
      _syncing = false;
    }
  }

  Future<void> _openSync() async {
    if (_cloud == null) return;
    final l = AppLocalizations.of(context)!;
    if (_cloud!.status == SyncStatus.conflict) {
      final keepLocal = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.syncTitle),
          content: Text(l.syncConflict),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.keepCloud),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.keepLocal),
            ),
          ],
        ),
      );
      if (!mounted || keepLocal == null) return;
      try {
        await _cloud!.resolve(keepLocal: keepLocal);
        await _controller.load();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l.homeSaveError)));
        }
      }
    } else {
      await _syncNow();
    }
  }

  Future<void> _deleteAccount() async {
    if (_deleting || widget.client == null) return;
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteAccount),
        content: Text(l.deleteAccountPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.deleteAccount),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _deleting = true);
    final userId = widget.client!.auth.currentUser?.id;
    try {
      final response = await widget.client!.functions.invoke('delete-account');
      if (response.status != 200 || response.data['deleted'] != true) {
        throw StateError('Deletion failed');
      }
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().where(
        (key) => key.startsWith('miga.') && key.contains('.$userId'),
      )) {
        await prefs.remove(key);
      }
      await widget.authService!.signOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.homeSaveError)));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await widget.authService!.signOut();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.homeSignOutError)),
      );
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Widget _body(AppTab tab) => switch (tab) {
    AppTab.home => HomeScreen(
      controller: _controller,
      userName: _userName,
      onProfile: () => _selectTab(AppTab.profile),
      onNotifications: _openNotifications,
      onPlan: () => _selectTab(AppTab.plan),
      onEditMeal: () =>
          _editMeal(_controller.selectedDate, _controller.selectedSlot),
      onRecipe: _openRecipe,
      onViewBudgetRecipes: _viewBudgetRecipes,
      onBrowseRecipes: () => _selectTab(AppTab.recipes),
      onPreferences: _editPreferences,
      onToggleFavorite: _toggleFavorite,
      onPlanRecipe: _planRecipe,
      onBudget: _editBudget,
      onGroceries: _openGroceries,
      onStores: _openStores,
      onPro: _openPro,
      onCookWithPantry: _cookWithPantry,
      onFindCheaper: _openSavings,
      onSurprise: _surpriseMe,
      onGenerateWeek: _autoPlan,
      surpriseRemaining: _surpriseRemaining,
      surpriseBusy: _surpriseBusy,
      isPro: !_requiresPro,
    ),
    AppTab.plan => MealPlanPage(
      week: _controller.week,
      mealCount: _controller.mealCount,
      loading: _controller.loading,
      loadFailed: _controller.loadFailed,
      canEdit: _controller.canEdit,
      mealFor: _controller.mealFor,
      onRetry: _controller.load,
      onEditMeal: _editMeal,
      onCopyDay: _copyDay,
      onChooseRecipe: _chooseRecipe,
      onMealAction: _transferMeal,
      onAutoPlan: _controller.canEdit ? _autoPlan : null,
      estimateFor: _controller.estimateFor,
      budget: _controller.budget,
      pricing: _controller.pricing,
      currency: _controller.costCurrency,
    ),
    AppTab.recipes => RecipesPage(
      repository: _recipes,
      onBack: () => setState(() => _tab = AppTab.home),
      budgetFilterRequest: _budgetRecipeFilterRequest,
      pantryFilterRequest: _pantryRecipeFilterRequest,
      onOpenRecipe: _controller.canEdit ? _openRecipe : null,
      preferences: _controller.preferences,
      pantry: _controller.availableIngredients,
      favorites: _controller.details.favorites,
      costFor: _controller.costFor,
      onFavorite: _toggleFavorite,
      budget: _controller.budget,
      now: _controller.now,
      portionFor: _controller.portionFor,
      onPantry: _editPantry,
    ),
    AppTab.groceries => GroceriesTabPage(
      items: _controller.details.groceries,
      isPro: !_requiresPro,
      onUpgrade: _openPro,
      currency: _controller.preferences.currency,
      onGenerate: _controller.canEdit ? _generateGroceryPlan : null,
      onCompare: _controller.canEdit ? _compareGroceryPrices : null,
      onComplete: _controller.canEdit
          ? () async {
              await _completeGroceryPurchase(_controller.details.groceries);
            }
          : null,
      onEdit: _controller.canEdit ? _openGroceries : null,
      onToggle: _controller.canEdit
          ? (changed) async {
              final items = List<GroceryItem>.of(_controller.details.groceries);
              final index = items.indexWhere(
                (item) =>
                    item.ingredientId != null && changed.ingredientId != null
                    ? item.ingredientId == changed.ingredientId
                    : item.name == changed.name,
              );
              if (index < 0) return false;
              items[index] = changed;
              return _controller.saveGroceries(items);
            }
          : null,
    ),
    AppTab.profile => ProfilePage(
      name: _userName,
      email: widget.authService?.session?.user.email,
      onBudget: _controller.canEdit ? _editBudget : null,
      onSignOut: widget.authService == null ? null : _signOut,
      signingOut: _signingOut,
      onPro: _openPro,
      onPreferences: _controller.canEdit ? _editPreferences : null,
      onPantry: _controller.canEdit ? _editPantry : null,
      onPrices: _controller.canEdit ? _editPrices : null,
      onSpending: _openSpending,
      onSavings: _openSavings,
      subscriptionActive: _purchases?.active ?? false,
      onSharedList: widget.client == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SharedGroceryPage(
                  client: widget.client!,
                  items: _controller.details.groceries,
                  currency: _controller.preferences.currency,
                  canCreate: !_requiresPro,
                  onUpgrade: _openPro,
                ),
              ),
            ),
      onPrivacy: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const PrivacyPage())),
      onDeleteAccount: widget.client == null || _deleting
          ? null
          : _deleteAccount,
      onSync: _cloud == null ? null : _openSync,
      syncLabel: _cloud == null
          ? null
          : switch (_cloud!.status) {
              SyncStatus.synced => AppLocalizations.of(context)!.syncSaved,
              SyncStatus.conflict => AppLocalizations.of(context)!.syncConflict,
              _ => AppLocalizations.of(context)!.syncPending,
            },
    ),
  };

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Theme(
        data: AppTheme.household(Theme.of(context)),
        child: Scaffold(
          backgroundColor: AppColors.cream,
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    _controller.setLanguage(
                      Localizations.localeOf(context).languageCode,
                    );
                    return Stack(
                      children: [
                        FadeTransition(
                          opacity: Tween<double>(begin: .84, end: 1)
                              .chain(CurveTween(curve: Curves.easeOut))
                              .animate(_tabAnimation),
                          child: IndexedStack(
                            index: _tab.index,
                            children: [
                              for (final tab in AppTab.values)
                                TickerMode(
                                  enabled: tab == _tab,
                                  child: SkeletonContent(
                                    loading: _controller.loading,
                                    skeleton: AppPageSkeleton(tab: tab),
                                    child: TickerMode(
                                      enabled: !_controller.loading,
                                      child: _body(tab),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: DeferredProgress(
                              active: _controller.saving || _controller.loading,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          bottomNavigationBar: AppBottomNavigation(
            selectedTab: _tab,
            onSelected: _selectTab,
          ),
        ),
      ),
    );
  }
}
