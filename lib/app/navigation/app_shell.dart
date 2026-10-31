import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:miga/app/navigation/app_tab.dart';
import 'package:miga/app/navigation/widgets/app_bottom_navigation.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/core/theme/app_theme.dart';
import 'package:miga/features/auth/domain/auth_service.dart';
import 'package:miga/features/budget/presentation/sheets/budget_editor_sheet.dart';
import 'package:miga/features/groceries/presentation/sheets/grocery_list_sheet.dart';
import 'package:miga/features/home/application/home_controller.dart';
import 'package:miga/features/home/data/local_home_details_store.dart';
import 'package:miga/features/home/domain/home_details_store.dart';
import 'package:miga/features/home/presentation/home_screen.dart';
import 'package:miga/features/meal_plan/data/local_meal_plan_store.dart';
import 'package:miga/features/meal_plan/domain/meal_plan_store.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';
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
  });

  final AuthService? authService;
  final MealPlanStore? planStore;
  final HomeDetailsStore? detailsStore;
  final DateTime? today;
  final Future<bool> Function(String languageCode) openNearbyStores;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  late final HomeController _controller;
  AppTab _tab = AppTab.home;
  bool _signingOut = false;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    final userId = widget.authService?.session?.user.id ?? 'guest';
    _controller = HomeController(
      today: widget.today ?? DateTime.now(),
      planStore: widget.planStore ?? LocalMealPlanStore(userId),
      detailsStore: widget.detailsStore ?? LocalHomeDetailsStore(userId),
    )..load();
    WidgetsBinding.instance.addObserver(this);
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
    _clockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.today == null) {
      _controller.syncTime(DateTime.now());
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

  Future<bool> _save(Future<bool> Function() action) async {
    if (!mounted) return false;
    final success = await action();
    if (!mounted) return success;
    if (success) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } else {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.homeSaveError),
          action: SnackBarAction(
            label: l10n.homeRetry,
            onPressed: () => _save(action),
          ),
        ),
      );
    }
    return success;
  }

  Future<void> _editMeal(
    DateTime date,
    MealSlot slot, {
    String? suggestion,
  }) async {
    if (!_controller.canEdit) return;
    final result = await showMealEditor(
      context,
      date: date,
      slot: slot,
      meal: _controller.mealFor(date, slot),
      suggestion: suggestion,
    );
    if (!mounted || result == null) return;
    final saved = await _save(() => _controller.saveMeal(date, slot, result));
    if (!mounted || !saved || result.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.mealAddedSuccess),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openRecipe(Recipe recipe) async {
    if (!_controller.canEdit) return;
    final date = _controller.selectedDate;
    final slot = recipe.slot;
    final add = await showRecipeDetails(
      context,
      recipe,
      onAddIngredients: _addIngredients,
    );
    if (!mounted || add != true) return;
    await _editMeal(
      date,
      slot,
      suggestion: recipe
          .contentFor(Localizations.localeOf(context).languageCode)
          .title,
    );
  }

  Future<void> _editBudget() async {
    if (!_controller.canEdit) return;
    final budget = await showBudgetEditor(context, _controller.budget);
    if (!mounted || budget == null) return;
    await _save(() => _controller.saveBudget(budget));
  }

  Future<void> _openGroceries() async {
    if (!_controller.canEdit) return;
    final items = await showGroceryList(
      context,
      _controller.details.groceries,
      currency: _controller.budget?.currency ?? 'DOP',
      onGenerateFromPlan: (items) =>
          _controller.generateGroceriesFromPlannedMeals(
            existingItems: items,
            languageCode: Localizations.localeOf(context).languageCode,
            currency: _controller.budget?.currency ?? 'DOP',
          ),
    );
    if (!mounted || items == null) return;
    await _save(() => _controller.saveGroceries(items));
  }

  Future<bool> _addIngredients(List<String> ingredients) async {
    if (!_controller.canEdit) return false;
    final items = List<GroceryItem>.of(_controller.details.groceries);
    for (final ingredient in ingredients) {
      if (!items.any(
        (item) => item.name.toLowerCase() == ingredient.toLowerCase(),
      )) {
        items.add(GroceryItem(ingredient));
      }
    }
    return _controller.saveGroceries(items);
  }

  Future<void> _planRecipe(Recipe recipe) => _editMeal(
    _controller.selectedDate,
    recipe.slot,
    suggestion: recipe
        .contentFor(Localizations.localeOf(context).languageCode)
        .title,
  );

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
          child: const ProPage(),
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
    final success = await _save(
      () => _controller.copyDayMeals(fromDate, targetDate),
    );
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.planCopySuccess(dates.formatShortMonthDay(targetDate)),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  Widget _body() => switch (_tab) {
    AppTab.home => HomeScreen(
      controller: _controller,
      userName: _userName,
      onProfile: () => setState(() => _tab = AppTab.profile),
      onPlan: () => setState(() => _tab = AppTab.plan),
      onEditMeal: () =>
          _editMeal(_controller.selectedDate, _controller.selectedSlot),
      onRecipe: _openRecipe,
      onPlanRecipe: _planRecipe,
      onBudget: _editBudget,
      onGroceries: _openGroceries,
      onStores: _openStores,
      onPro: _openPro,
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
    ),
    AppTab.recipes => RecipesPage(
      onOpenRecipe: _controller.canEdit ? _openRecipe : null,
    ),
    AppTab.profile => ProfilePage(
      name: _userName,
      email: widget.authService?.session?.user.email,
      onBudget: _controller.canEdit ? _editBudget : null,
      onSignOut: widget.authService == null ? null : _signOut,
      signingOut: _signingOut,
      onPro: _openPro,
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
                  builder: (context, _) => _body(),
                ),
              ),
            ),
          ),
          bottomNavigationBar: AppBottomNavigation(
            selectedTab: _tab,
            onSelected: (tab) => setState(() => _tab = tab),
          ),
        ),
      ),
    );
  }
}
