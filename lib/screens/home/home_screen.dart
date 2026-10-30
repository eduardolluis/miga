import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/home_details_store.dart';
import '../../services/meal_plan_store.dart';
import '../../theme/app_colors.dart';
import 'budget_editor_sheet.dart';
import 'grocery_list_sheet.dart';
import 'home_controller.dart';
import 'home_dashboard.dart';
import 'home_plan_page.dart';
import 'home_profile_page.dart';
import 'home_recipe_card.dart';
import 'home_stores_sheet.dart';
import 'meal_editor_sheet.dart';
import 'meal_slot.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.authService,
    this.planStore,
    this.detailsStore,
    this.today,
  });

  final AuthService? authService;
  final MealPlanStore? planStore;
  final HomeDetailsStore? detailsStore;
  final DateTime? today;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;
  int _tab = 0;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    final userId = widget.authService?.session?.user.id ?? 'guest';
    _controller = HomeController(
      today: widget.today ?? DateTime.now(),
      planStore: widget.planStore ?? LocalMealPlanStore(userId),
      detailsStore: widget.detailsStore ?? HomeDetailsStore(userId),
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(Future<bool> Function() action) async {
    if (!mounted) return;
    final success = await action();
    if (!mounted) return;
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
    await _save(() => _controller.saveMeal(date, slot, result));
  }

  Future<void> _openRecipe() async {
    if (!_controller.canEdit) return;
    final date = _controller.selectedDate;
    final slot = _controller.selectedSlot;
    final add = await showHomeRecipe(context);
    if (!mounted || add != true) return;
    await _editMeal(
      date,
      slot,
      suggestion: AppLocalizations.of(context)!.homeRecipeTitle,
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
    final items = await showGroceryList(context, _controller.details.groceries);
    if (!mounted || items == null) return;
    await _save(() => _controller.saveGroceries(items));
  }

  Future<void> _openStores() async {
    final openList = await showStoresEmptyState(context);
    if (mounted && openList == true) await _openGroceries();
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

  Widget _body(AppLocalizations l10n) => switch (_tab) {
    0 => HomeDashboard(
      controller: _controller,
      onProfile: () => setState(() => _tab = 3),
      onPlan: () => setState(() => _tab = 1),
      onEditMeal: () =>
          _editMeal(_controller.selectedDate, _controller.selectedSlot),
      onRecipe: _openRecipe,
      onBudget: _editBudget,
      onGroceries: _openGroceries,
      onStores: _openStores,
    ),
    1 => HomePlanPage(controller: _controller, onEditMeal: _editMeal),
    2 => ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text(
          l10n.homeInspiration,
          style: const TextStyle(fontFamily: 'LiberationSerif', fontSize: 32),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.homeRecipeSubtitle,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        HomeRecipeCard(onTap: _controller.canEdit ? _openRecipe : null),
      ],
    ),
    _ => HomeProfilePage(
      name:
          widget.authService?.session?.user.userMetadata?['full_name']
              as String?,
      email: widget.authService?.session?.user.email,
      onBudget: _controller.canEdit ? _editBudget : null,
      onSignOut: widget.authService == null ? null : _signOut,
      signingOut: _signingOut,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: AppColors.olive,
            onPrimary: Colors.white,
            surface: AppColors.cream,
            onSurface: AppColors.ink,
          ),
          textTheme: theme.textTheme.apply(
            bodyColor: AppColors.ink,
            displayColor: AppColors.ink,
          ),
          navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: AppColors.cream,
            indicatorColor: Color(0xFFE4E8D8),
            elevation: 0,
          ),
        ),
        child: Scaffold(
          backgroundColor: AppColors.cream,
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => _body(l10n),
                ),
              ),
            ),
          ),
          bottomNavigationBar: NavigationBar(
            height: 76,
            selectedIndex: _tab,
            onDestinationSelected: (tab) => setState(() => _tab = tab),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: l10n.homeNavHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month_rounded),
                label: l10n.homeNavPlan,
              ),
              NavigationDestination(
                icon: const Icon(Icons.restaurant_menu_outlined),
                label: l10n.homeNavRecipes,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded),
                label: l10n.homeNavProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
