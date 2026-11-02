import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show setEquals;

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
    this.rotationIndex = 0,
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
  final int rotationIndex;
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
  _RecipeSort _sort = _RecipeSort.recommended;
  final ScrollController _scroll = ScrollController(keepScrollOffset: false);
  final TextEditingController _search = TextEditingController();
  Timer? _searchDebounce;
  List<Recipe>? _eligibleCache;
  int _eligibleCacheVersion = 0;
  int _observedRepositoryRevision = 0;
  String? _eligibleCacheLanguage;

  @override
  void initState() {
    super.initState();
    _cheap = widget.budgetFilterRequest > 0;
    _pantry = widget.pantryFilterRequest > 0;
    _observedRepositoryRevision = widget.repository.revision;
  }

  @override
  void didUpdateWidget(covariant RecipesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final preferencesChanged =
        widget.preferences.country != oldWidget.preferences.country ||
        widget.preferences.currency != oldWidget.preferences.currency ||
        widget.preferences.language != oldWidget.preferences.language ||
        widget.preferences.members != oldWidget.preferences.members ||
        !setEquals(
          widget.preferences.restrictions,
          oldWidget.preferences.restrictions,
        ) ||
        !setEquals(widget.preferences.disliked, oldWidget.preferences.disliked);
    final budgetChanged =
        widget.budget?.limit != oldWidget.budget?.limit ||
        widget.budget?.spent != oldWidget.budget?.spent ||
        widget.budget?.currency != oldWidget.budget?.currency;
    final favoritesChanged = !setEquals(widget.favorites, oldWidget.favorites);
    final activeFavoritesChanged = _favorites && favoritesChanged;
    final filtersChanged =
        preferencesChanged ||
        budgetChanged ||
        activeFavoritesChanged ||
        !setEquals(widget.pantry, oldWidget.pantry) ||
        widget.rotationIndex != oldWidget.rotationIndex ||
        widget.budgetFilterRequest != oldWidget.budgetFilterRequest ||
        widget.pantryFilterRequest != oldWidget.pantryFilterRequest ||
        widget.costFor != oldWidget.costFor ||
        widget.portionFor != oldWidget.portionFor ||
        widget.now != oldWidget.now;
    if (filtersChanged || !identical(widget.repository, oldWidget.repository)) {
      _invalidateEligibleCache();
      _page = 0;
    }
    if (widget.budgetFilterRequest != oldWidget.budgetFilterRequest ||
        widget.pantryFilterRequest != oldWidget.pantryFilterRequest) {
      _searchDebounce?.cancel();
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
    final oldSlot = _slot;
    final oldAvailable = {..._available};
    final oldQuick = _quick;
    final oldProtein = _protein;
    final oldCheap = _cheap;
    final oldFavorites = _favorites;
    final oldPantry = _pantry;
    final oldSort = _sort;
    var changed = false;
    setState(() {
      change();
      changed =
          oldSlot != _slot ||
          !setEquals(oldAvailable, _available) ||
          oldQuick != _quick ||
          oldProtein != _protein ||
          oldCheap != _cheap ||
          oldFavorites != _favorites ||
          oldPantry != _pantry ||
          oldSort != _sort;
      if (changed) _page = 0;
    });
    if (!changed) return;
    _invalidateEligibleCache();
    _scrollToStart();
  }

  void _invalidateEligibleCache() {
    _eligibleCache = null;
    _eligibleCacheLanguage = null;
    _eligibleCacheVersion++;
  }

  List<Recipe> _eligibleRecipes(String language) {
    if (_eligibleCacheLanguage != language) _invalidateEligibleCache();
    final cached = _eligibleCache;
    if (cached != null) return cached;
    final recipes = _filtered(language, includeSearch: false);
    _eligibleCache = recipes;
    _eligibleCacheLanguage = language;
    return recipes;
  }

  void _goToPage(int page) {
    FocusScope.of(context).unfocus();
    setState(() => _page = page);
    _scrollToStart();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
    final matchesById = <String, int>{};
    final costsById = <String, RecipeCost>{};
    final recipes = <Recipe>[];
    for (final original in widget.repository.all) {
      if (!widget.preferences.allows(original)) continue;
      final recipe = widget.portionFor?.call(original) ?? original;
      if (_quick && recipe.minutes > 20) continue;
      if (_protein && (recipe.nutrition?.proteinGrams ?? 0) < 25) continue;
      if (_favorites && !widget.favorites.contains(recipe.id)) continue;
      if (includeSearch && _slot != null && recipe.slot != _slot) continue;
      if (available.isNotEmpty) {
        final matches = recipe.matchingIngredients(available);
        if (matches == 0) continue;
        matchesById[recipe.id] = matches;
      }
      if (_cheap) {
        if (allowance == null || widget.costFor == null) continue;
        final cost = widget.costFor!(recipe);
        if (!cost.fits(allowance)) continue;
        costsById[recipe.id] = cost;
      }
      if (includeSearch &&
          !recipe.contentFor(language).title.toLowerCase().contains(query)) {
        continue;
      }
      recipes.add(recipe);
    }
    recipes.sort((a, b) {
      if (_sort == _RecipeSort.newest) {
        return b.sortOrder.compareTo(a.sortOrder);
      }
      if (_sort == _RecipeSort.quickest) {
        return a.minutes.compareTo(b.minutes);
      }
      if (available.isNotEmpty) {
        final match = matchesById[b.id]!.compareTo(matchesById[a.id]!);
        if (match != 0) return match;
      }
      if (_cheap && widget.costFor != null) {
        return costsById[a.id]!.subtotalCents.compareTo(
          costsById[b.id]!.subtotalCents,
        );
      }
      return a.sortOrder.compareTo(b.sortOrder);
    });
    // Recommended mode changes across app launches, but never within a
    // session. Explicit Newest/Quickest ordering remains deterministic.
    if (_sort == _RecipeSort.recommended && recipes.length > 1) {
      final start = widget.rotationIndex % recipes.length;
      return [...recipes.skip(start), ...recipes.take(start)];
    }
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
    if (_observedRepositoryRevision != widget.repository.revision) {
      _observedRepositoryRevision = widget.repository.revision;
      _invalidateEligibleCache();
    }
    final language = Localizations.localeOf(context).languageCode;
    final eligible = _eligibleRecipes(language);
    final key =
        '${widget.repository.revision}|${widget.repository.offline}|${widget.rotationIndex}|$_page|$_query|$_slot|$language|$_eligibleCacheVersion';
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
    final available = {..._available, if (_pantry) ...widget.pantry};

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
                        onChanged: (value) {
                          _searchDebounce?.cancel();
                          _searchDebounce = Timer(
                            const Duration(milliseconds: 250),
                            () {
                              if (!mounted || _query == value) return;
                              setState(() {
                                _query = value;
                                _page = 0;
                              });
                              _scrollToStart();
                            },
                          );
                        },
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
                      _invalidateEligibleCache();
                      setState(() => _requestKey = null);
                      await widget.repository.refresh();
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
                    // The generated l10n method orders its arguments as
                    // (end, start, total), not as shown in the ARB template.
                    l.recipePageRange(
                      start + visibleRecipes.length,
                      start + 1,
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
            sliver: SliverGrid.builder(
              itemCount: visibleRecipes.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio:
                    MediaQuery.textScalerOf(context).scale(14) > 19 ? .48 : .83,
              ),
              itemBuilder: (context, index) {
                final recipe = visibleRecipes[index];
                final cost = widget.costFor?.call(recipe);
                final matches = available.isEmpty
                    ? null
                    : recipe.matchingIngredients(available);
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
                  ingredientSummary: matches == null
                      ? null
                      : l.recipeIngredientMatch(
                          matches,
                          recipe.ingredients.length - matches,
                        ),
                  onTap: widget.onOpenRecipe == null
                      ? null
                      : () => widget.onOpenRecipe!(recipe),
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
