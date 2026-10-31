import 'package:flutter/material.dart';

import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/meal_plan/presentation/meal_slot_presentation.dart';
import 'package:miga/features/recipes/data/recipe_catalog.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_card.dart';
import 'package:miga/l10n/app_localizations.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key, required this.onOpenRecipe});
  final ValueChanged<Recipe>? onOpenRecipe;

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  MealSlot? _slot;
  String _query = '';
  final _available = <RecipeIngredient>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final recipes = RecipeCatalog.all
        .where(
          (recipe) =>
              (_slot == null || recipe.slot == _slot) &&
              (_available.isEmpty ||
                  recipe.matchingIngredients(_available) > 0) &&
              recipe
                  .contentFor(language)
                  .title
                  .toLowerCase()
                  .contains(_query.toLowerCase().trim()),
        )
        .toList();
    if (_available.isNotEmpty) {
      recipes.sort((a, b) {
        final matches = b
            .matchingIngredients(_available)
            .compareTo(a.matchingIngredients(_available));
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
            ingredientSummary: _available.isEmpty
                ? null
                : l10n.recipeIngredientMatch(
                    recipe.matchingIngredients(_available),
                    recipe.ingredients.length -
                        recipe.matchingIngredients(_available),
                  ),
            onTap: widget.onOpenRecipe == null
                ? null
                : () => widget.onOpenRecipe!(recipe),
          ),
      ],
    );
  }
}
