import 'package:flutter/material.dart';

import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/meal_plan/presentation/meal_slot_presentation.dart';
import 'package:miga/features/recipes/data/recipe_catalog.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_card.dart';
import 'package:miga/l10n/app_localizations.dart';
import 'package:miga/features/profile/domain/household_preferences.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({
    super.key,
    required this.onOpenRecipe,
    this.preferences = const HouseholdPreferences(),
    this.pantry = const {},
    this.favorites = const {},
    this.costFor,
    this.onFavorite,
    this.budget,
    this.portionFor,
    this.now,
    this.onPantry,
  });
  final ValueChanged<Recipe>? onOpenRecipe;
  final HouseholdPreferences preferences;
  final Set<RecipeIngredient> pantry;
  final Set<String> favorites;
  final RecipeCost Function(Recipe)? costFor;
  final ValueChanged<String>? onFavorite;
  final WeeklyBudget? budget;
  final Recipe Function(Recipe)? portionFor;
  final DateTime? now;
  final VoidCallback? onPantry;

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  MealSlot? _slot;
  String _query = '';
  final _available = <RecipeIngredient>{};
  bool _quick = false,
      _protein = false,
      _cheap = false,
      _favorites = false,
      _pantry = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final available = {..._available, if (_pantry) ...widget.pantry};
    final allowance =
        widget.budget == null ||
            widget.budget!.currency != widget.preferences.currency
        ? null
        : mealAllowanceCents(widget.budget!, widget.now ?? DateTime.now());
    final recipes = RecipeCatalog.all
        .where(widget.preferences.allows)
        .map((r) => widget.portionFor?.call(r) ?? r)
        .where(
          (recipe) =>
              (!_quick || recipe.minutes <= 20) &&
              (!_protein || (recipe.nutrition?.proteinGrams ?? 0) >= 25) &&
              (!_favorites || widget.favorites.contains(recipe.id)) &&
              (!_cheap ||
                  (allowance != null &&
                      (widget.costFor?.call(recipe).fits(allowance) ??
                          false))) &&
              (_slot == null || recipe.slot == _slot) &&
              (available.isEmpty ||
                  recipe.matchingIngredients(available) > 0) &&
              recipe
                  .contentFor(language)
                  .title
                  .toLowerCase()
                  .contains(_query.toLowerCase().trim()),
        )
        .toList();
    if (available.isNotEmpty) {
      recipes.sort((a, b) {
        final matches = b
            .matchingIngredients(available)
            .compareTo(a.matchingIngredients(available));
        return matches != 0 ? matches : a.imageIndex.compareTo(b.imageIndex);
      });
    }
    final ingredients = RecipeIngredient.values.toList()
      ..sort((a, b) => a.label(language).compareTo(b.label(language)));
    return ListView(
      key: const PageStorageKey('recipes-catalog'),
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          l10n.homeNavRecipes,
          style: const TextStyle(fontFamily: 'LiberationSerif', fontSize: 32),
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: l10n.recipeSearch,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.recipeAll),
              selected: _slot == null,
              onSelected: (_) => setState(() => _slot = null),
            ),
            for (final slot in MealSlot.values)
              ChoiceChip(
                label: Text(slot.label(l10n)),
                selected: _slot == slot,
                onSelected: (_) => setState(() => _slot = slot),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: Text(l10n.quickFilter),
              selected: _quick,
              onSelected: (v) => setState(() => _quick = v),
            ),
            FilterChip(
              label: Text(l10n.proteinFilter),
              selected: _protein,
              onSelected: (v) => setState(() => _protein = v),
            ),
            FilterChip(
              label: Text(l10n.cheapFilter),
              selected: _cheap,
              onSelected: widget.budget == null
                  ? null
                  : (v) => setState(() => _cheap = v),
            ),
            FilterChip(
              label: Text(l10n.favoritesFilter),
              selected: _favorites,
              onSelected: (v) => setState(() => _favorites = v),
            ),
            FilterChip(
              label: Text(l10n.pantryFilter),
              selected: _pantry,
              onSelected: (v) => setState(() => _pantry = v),
            ),
          ],
        ),
        if (widget.onPantry != null)
          TextButton.icon(
            onPressed: widget.onPantry,
            icon: const Icon(Icons.kitchen_outlined),
            label: Text(l10n.pantryTitle),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.recipeHaveIngredients,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (_available.isNotEmpty)
              TextButton(
                onPressed: () => setState(_available.clear),
                child: Text(l10n.recipeClearIngredients),
              ),
          ],
        ),
        Text(l10n.recipeIngredientsHint),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final ingredient in ingredients)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    key: ValueKey('ingredient-${ingredient.name}'),
                    label: Text(ingredient.label(language)),
                    selected: _available.contains(ingredient),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _available.add(ingredient);
                      } else {
                        _available.remove(ingredient);
                      }
                    }),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (recipes.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.recipeNoResults),
          ),
        for (final recipe in recipes)
          RecipeCard(
            recipe: recipe,
            favorite: widget.favorites.contains(recipe.id),
            onFavorite: widget.onFavorite == null
                ? null
                : () => widget.onFavorite!(recipe.id),
            costLabel: widget.costFor == null
                ? null
                : widget.costFor!(recipe).complete
                ? l10n.recipeCostPerServing(
                    WeeklyBudget(
                      limit: 0,
                      spent: 0,
                      currency: widget.preferences.currency,
                    ).format(widget.costFor!(recipe).perServingCents / 100),
                  )
                : l10n.groceryEstimateUnavailable,
            ingredientSummary: available.isEmpty
                ? null
                : l10n.recipeIngredientMatch(
                    recipe.matchingIngredients(available),
                    recipe.ingredients.length -
                        recipe.matchingIngredients(available),
                  ),
            onTap: widget.onOpenRecipe == null
                ? null
                : () => widget.onOpenRecipe!(recipe),
          ),
      ],
    );
  }
}
