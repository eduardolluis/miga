import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/core/ui/miga_skeleton.dart';
import 'package:miga/core/ui/miga_ui_copy.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/meal_plan/presentation/meal_slot_presentation.dart';
import 'package:miga/features/profile/domain/household_preferences.dart';
import 'package:miga/features/recipes/data/recipe_repository.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_card.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_pagination.dart';
import 'package:miga/features/recipes/presentation/sheets/recipe_filters_sheet.dart';
import 'package:miga/l10n/app_localizations.dart';

enum _RecipeSort { recommended, newest, quickest }

/// Responsive two-column recipe catalog. The Home budget CTA increments
/// [budgetFilterRequest], so it also works when the tab has been opened before.
class RecipesPage extends StatefulWidget {
  const RecipesPage({
    super.key,
    required this.onOpenRecipe,
    required this.repository,
    this.onBack,
    this.preferences = const HouseholdPreferences(),
    this.pantry = const {},
    this.favorites = const {},
    this.costFor,
    this.onFavorite,
    this.budget,
    this.portionFor,
    this.now,
    this.onPantry,
    this.budgetFilterRequest = 0,
    this.pantryFilterRequest = 0,
  });

  final ValueChanged<Recipe>? onOpenRecipe;
  final RecipeRepository repository;
  final VoidCallback? onBack;
  final HouseholdPreferences preferences;
  final Set<RecipeIngredient> pantry;
  final Set<String> favorites;
  final RecipeCost Function(Recipe)? costFor;
  final ValueChanged<String>? onFavorite;
  final WeeklyBudget? budget;
  final Recipe Function(Recipe)? portionFor;
  final DateTime? now;
  final VoidCallback? onPantry;
  final int budgetFilterRequest;
  final int pantryFilterRequest;

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  static const _pageSize = 6;
  int _page = 0;
  MealSlot? _slot;
  String _query = '';
  final _available = <RecipeIngredient>{};
  bool _quick = false;
  bool _protein = false;
  bool _cheap = false;
  bool _favorites = false;
  bool _pantry = false;
  _RecipeSort _sort = _RecipeSort.newest;
  final ScrollController _scroll = ScrollController(keepScrollOffset: false);
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cheap = widget.budgetFilterRequest > 0;
    _pantry = widget.pantryFilterRequest > 0;
  }

  @override
  void didUpdateWidget(covariant RecipesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_page > 0) {
      final count =
          (_filtered(Localizations.localeOf(context).languageCode).length /
                  _pageSize)
              .ceil();
      _page = count == 0 ? 0 : _page.clamp(0, count - 1);
    }
    if (widget.budgetFilterRequest != oldWidget.budgetFilterRequest ||
        widget.pantryFilterRequest != oldWidget.pantryFilterRequest) {
      // Each Home shortcut opens a fresh filtered catalog, even if already
      // mounted in IndexedStack.
      _page = 0;
      _cheap =
          widget.budgetFilterRequest > 0 && widget.pantryFilterRequest == 0;
      _slot = null;
      _query = '';
      _quick = false;
      _protein = false;
      _favorites = false;
      _pantry = widget.pantryFilterRequest > 0;
      _available.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _search.clear();
        if (_scroll.hasClients) _scroll.jumpTo(0);
      });
    }
  }

  void _scrollToStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  void _changeFilters(VoidCallback change) {
    setState(() {
      change();
      _page = 0;
    });
    _scrollToStart();
  }

  void _goToPage(int page) {
    FocusScope.of(context).unfocus();
    setState(() => _page = page);
    _scrollToStart();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  int? get _allowance {
    if (widget.budget == null ||
        widget.budget!.currency != widget.preferences.currency) {
      return null;
    }
    return mealAllowanceCents(widget.budget!, widget.now ?? DateTime.now());
  }

  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();
    final result = await showModalBottomSheet<RecipeFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.cream,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: RecipeFiltersSheet(
          initial: RecipeFilters(
            cheap: _cheap,
            quick: _quick,
            protein: _protein,
            favorites: _favorites,
            pantry: _pantry,
            ingredients: {..._available},
          ),
          hasBudget:
              widget.budget != null &&
              widget.costFor != null &&
              _allowance != null,
          onPantry: widget.onPantry,
        ),
      ),
    );
    if (!mounted || result == null) return;
    _changeFilters(() {
      _cheap = result.cheap;
      _quick = result.quick;
      _protein = result.protein;
      _favorites = result.favorites;
      _pantry = result.pantry;
      _available
        ..clear()
        ..addAll(result.ingredients);
    });
  }

  List<Recipe> _filtered(String language, {bool includeSearch = true}) {
    final available = {..._available, if (_pantry) ...widget.pantry};
    final allowance = _allowance;
    final query = _query.toLowerCase().trim();
    final recipes = widget.repository.all
        .where(widget.preferences.allows)
        .map((r) => widget.portionFor?.call(r) ?? r)
        .where((r) {
          if (_quick && r.minutes > 20) return false;
          if (_protein && (r.nutrition?.proteinGrams ?? 0) < 25) return false;
          if (_favorites && !widget.favorites.contains(r.id)) return false;
          if (includeSearch && _slot != null && r.slot != _slot) return false;
          if (available.isNotEmpty && r.matchingIngredients(available) == 0) {
            return false;
          }
          if (_cheap &&
              (allowance == null ||
                  !(widget.costFor?.call(r).fits(allowance) ?? false))) {
            return false;
          }
          return !includeSearch ||
              r.contentFor(language).title.toLowerCase().contains(query);
        })
        .toList();
    recipes.sort((a, b) {
      if (_sort == _RecipeSort.newest) {
        return b.sortOrder.compareTo(a.sortOrder);
      }
      if (_sort == _RecipeSort.quickest) {
        return a.minutes.compareTo(b.minutes);
      }
      if (available.isNotEmpty) {
        final match = b
            .matchingIngredients(available)
            .compareTo(a.matchingIngredients(available));
        if (match != 0) return match;
      }
      if (_cheap && widget.costFor != null) {
        return widget.costFor!(a).subtotalCents.compareTo(
          widget.costFor!(b).subtotalCents,
        );
      }
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return recipes;
  }

  String? _requestKey;
  Future<RecipePage>? _request;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.repository,
    builder: (context, _) => _buildCatalog(context),
  );

  Widget _buildCatalog(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final eligible = _filtered(language, includeSearch: false);
    final key =
        '${widget.repository.revision}|${widget.repository.offline}|$_page|$_query|$_slot|$language|${eligible.map((r) => '${r.id}:${r.servings}').join(',')}';
    if (_requestKey != key) {
      _requestKey = key;
      _request = widget.repository.search(
        eligible: eligible,
        query: _query,
        language: language,
        slot: _slot,
        page: _page,
        pageSize: _pageSize,
      );
    }
    return FutureBuilder<RecipePage>(
      key: ValueKey(key),
      future: _request,
      builder: (context, snapshot) => _buildPage(context, snapshot),
    );
  }

  Widget _buildPage(BuildContext context, AsyncSnapshot<RecipePage> snapshot) {
    final l = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final loading =
        snapshot.connectionState != ConnectionState.done ||
        (widget.repository.loading && widget.repository.all.isEmpty);
    final result = snapshot.data ?? const RecipePage([], 0);
    final recipes = result.recipes;
    final total = result.total;
    final pages = (total / _pageSize).ceil();
    final page = pages == 0 ? 0 : _page.clamp(0, pages - 1);
    final start = page * _pageSize;
    final visibleRecipes = recipes;
    final onPrevious = page > 0 ? () => _goToPage(page - 1) : null;
    final onNext = page + 1 < pages ? () => _goToPage(page + 1) : null;
    final activeExtras =
        [_cheap, _quick, _protein, _favorites, _pantry].where((v) => v).length +
        _available.length;
    final hasBudget =
        widget.budget != null && widget.costFor != null && _allowance != null;

    return CustomScrollView(
      key: const PageStorageKey('recipes-catalog'),
      controller: _scroll,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 46,
                  child: Row(
                    children: [
                      IconButton(
                        key: const ValueKey('recipes-back-home'),
                        tooltip: MaterialLocalizations.of(context)
                            .backButtonTooltip,
                        onPressed: widget.onBack,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l.homeNavRecipes,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 17),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('recipe-search'),
                        onChanged: (value) =>
                            _changeFilters(() => _query = value),
                        controller: _search,
                        decoration: InputDecoration(
                          hintText: l.recipeSearch,
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: const Color(0xFFEFEDE6),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(26),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(26),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      key: const ValueKey('recipe-filters-button'),
                      tooltip: MigaUiCopy.filters(context),
                      onPressed: _openFilters,
                      icon: Badge(
                        isLabelVisible: activeExtras > 0,
                        label: Text('$activeExtras'),
                        child: const Icon(Icons.tune_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_cheap) ...[
                        InputChip(
                          key: const ValueKey('within-budget-filter'),
                          label: Text(MigaUiCopy.withinBudget(context)),
                          selected: true,
                          onDeleted: () => _changeFilters(() => _cheap = false),
                          onPressed: () => _changeFilters(() => _cheap = false),
                        ),
                        const SizedBox(width: 8),
                      ],
                      ChoiceChip(
                        label: Text(l.recipeAll),
                        selected: _slot == null,
                        onSelected: (_) => _changeFilters(() => _slot = null),
                      ),
                      for (final slot in MealSlot.values) ...[
                        const SizedBox(width: 7),
                        ChoiceChip(
                          label: Text(slot.label(l)),
                          selected: _slot == slot,
                          onSelected: (_) => _changeFilters(() => _slot = slot),
                        ),
                      ],
                    ],
                  ),
                ),
                if (activeExtras > (_cheap ? 1 : 0))
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (_quick)
                          InputChip(
                            label: Text(l.quickFilter),
                            onDeleted: () =>
                                _changeFilters(() => _quick = false),
                          ),
                        if (_protein)
                          InputChip(
                            label: Text(l.proteinFilter),
                            onDeleted: () =>
                                _changeFilters(() => _protein = false),
                          ),
                        if (_favorites)
                          InputChip(
                            label: Text(l.favoritesFilter),
                            onDeleted: () =>
                                _changeFilters(() => _favorites = false),
                          ),
                        if (_pantry)
                          InputChip(
                            key: const ValueKey('pantry-filter'),
                            label: Text(l.pantryFilter),
                            onDeleted: () =>
                                _changeFilters(() => _pantry = false),
                          ),
                        for (final ingredient in _available)
                          InputChip(
                            label: Text(ingredient.label(language)),
                            onDeleted: () => _changeFilters(
                              () => _available.remove(ingredient),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (result.offline || widget.repository.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    MigaUiCopy.choose(
                      context,
                      widget.repository.all.isEmpty
                          ? 'No pudimos cargar las recetas.'
                          : 'Mostrando recetas guardadas sin conexión.',
                      widget.repository.all.isEmpty
                          ? 'Could not load recipes.'
                          : 'Showing saved recipes offline.',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await widget.repository.refresh();
                      if (mounted) setState(() => _requestKey = null);
                    },
                    child: Text(l.homeRetry),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      MigaUiCopy.totalRecipes(context, total),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    PopupMenuButton<_RecipeSort>(
                      key: const ValueKey('recipes-sort'),
                      tooltip: MigaUiCopy.sort(context),
                      onSelected: (value) =>
                          _changeFilters(() => _sort = value),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: _RecipeSort.recommended,
                          child: Text(MigaUiCopy.recommended(context)),
                        ),
                        PopupMenuItem(
                          value: _RecipeSort.newest,
                          child: Text(MigaUiCopy.newest(context)),
                        ),
                        PopupMenuItem(
                          value: _RecipeSort.quickest,
                          child: Text(MigaUiCopy.quickest(context)),
                        ),
                      ],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(switch (_sort) {
                            _RecipeSort.recommended => MigaUiCopy.recommended(
                              context,
                            ),
                            _RecipeSort.newest => MigaUiCopy.newest(context),
                            _RecipeSort.quickest => MigaUiCopy.quickest(
                              context,
                            ),
                          }, style: const TextStyle(fontSize: 12)),
                          const Icon(Icons.expand_more_rounded),
                        ],
                      ),
                    ),
                  ],
                ),
                if (pages > 1) ...[
                  const SizedBox(height: 16),
                  Text(
                    l.recipePageRange(
                      start + 1,
                      start + visibleRecipes.length,
                      total,
                    ),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (loading)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(22, 6, 22, 18),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  SkeletonRecipeCards(),
                  SizedBox(height: 12),
                  SkeletonRecipeCards(),
                ],
              ),
            ),
          )
        else if (recipes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  _cheap && !hasBudget
                      ? MigaUiCopy.budgetUnknown(context)
                      : _cheap
                      ? l.budgetNoConfirmedFit
                      : l.recipeNoResults,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 18),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                return SliverGrid.builder(
                  itemCount: visibleRecipes.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio:
                        MediaQuery.textScalerOf(context).scale(14) > 19
                        ? .48
                        : .83,
                  ),
                  itemBuilder: (context, index) {
                    final recipe = visibleRecipes[index];
                    final cost = widget.costFor?.call(recipe);
                    final available = {
                      ..._available,
                      if (_pantry) ...widget.pantry,
                    };
                    final priced = cost?.ingredients
                        .where((line) => line.cents != null)
                        .length;
                    final costLabel = cost == null
                        ? null
                        : cost.complete
                        ? '≈ ${widget.budget?.format(cost.subtotalCents / 100) ?? WeeklyBudget(limit: 0, spent: 0, currency: widget.preferences.currency).format(cost.subtotalCents / 100)}'
                        : MigaUiCopy.incompletePrices(
                            context,
                            priced ?? 0,
                            cost.ingredients.length,
                          );
                    return RecipeCard(
                      recipe: recipe,
                      favorite: widget.favorites.contains(recipe.id),
                      onFavorite: widget.onFavorite == null
                          ? null
                          : () => widget.onFavorite!(recipe.id),
                      costLabel: costLabel,
                      ingredientSummary: available.isEmpty
                          ? null
                          : l.recipeIngredientMatch(
                              recipe.matchingIngredients(available),
                              recipe.ingredients.length -
                                  recipe.matchingIngredients(available),
                            ),
                      onTap: widget.onOpenRecipe == null
                          ? null
                          : () => widget.onOpenRecipe!(recipe),
                    );
                  },
                );
              },
            ),
          ),
        if (pages > 1)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
            sliver: SliverToBoxAdapter(
              child: RecipePagination(
                page: page,
                pages: pages,
                onPrevious: onPrevious,
                onNext: onNext,
              ),
            ),
          ),
      ],
    );
  }
}
