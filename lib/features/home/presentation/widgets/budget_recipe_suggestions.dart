import 'package:flutter/material.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/core/ui/miga_ui_copy.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/home/presentation/widgets/recipe_cost_sheet.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_image.dart';
import 'package:miga/features/recipes/presentation/widgets/favorite_heart_icon.dart';
import 'package:miga/l10n/app_localizations.dart';

/// A compact preview of two meals, not the full budget catalog. Prices refer
/// to the complete packages needed to buy the ingredients for the recipe.
class BudgetRecipeSuggestions extends StatefulWidget {
  const BudgetRecipeSuggestions({
    super.key,
    this.budget,
    this.currency = 'DOP',
    required this.now,
    required this.recipes,
    required this.onRecipe,
    this.onSeeAll,
    this.estimate,
    this.costFor,
    this.pricing = false,
    this.priceRevision = 0,
    this.ingredientPrices,
    this.favorites = const {},
    this.onFavorite,
  });

  /// Null when the user has not set up a weekly budget in Profile.
  final WeeklyBudget? budget;
  final String currency;
  final DateTime now;
  final List<Recipe> recipes;
  final ValueChanged<Recipe> onRecipe;
  final VoidCallback? onSeeAll;
  final Set<String> favorites;
  final ValueChanged<String>? onFavorite;
  final Future<List<RecipeCost>> Function(List<Recipe>)? estimate;
  final RecipeCost Function(Recipe)? costFor;
  final bool pricing;
  // Only refresh cost estimates when prices or recipes actually change.
  final int priceRevision;
  final Map<String, int>? ingredientPrices;

  @override
  State<BudgetRecipeSuggestions> createState() =>
      _BudgetRecipeSuggestionsState();
}

class _BudgetRecipeSuggestionsState extends State<BudgetRecipeSuggestions> {
  final _estimator = RecipeCostEstimator();
  late Future<List<RecipeCost>> _request = _load();

  // Recipe discovery must not disappear if pricing is unavailable or the user
  // has not configured a budget. In that situation, costs remain unpriced.
  Future<List<RecipeCost>> _load() async {
    try {
      if (widget.estimate != null) {
        return await widget.estimate!(widget.recipes);
      }
      if (widget.currency == 'DOP') {
        return await _estimator.estimate(widget.recipes);
      }
    } catch (_) {
      // Pricing is best-effort; recipes are still usable offline.
    }
    return [
      for (final recipe in widget.recipes)
        RecipeCost(recipe, [
          for (final amount in RecipeAmounts.forRecipe(recipe))
            IngredientCost(amount),
        ]),
    ];
  }

  WeeklyBudget get _displayBudget =>
      widget.budget ??
      WeeklyBudget(limit: 0, spent: 0, currency: widget.currency);

  @override
  void didUpdateWidget(BudgetRecipeSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.costFor != null) return;
    if (oldWidget.budget?.currency != widget.budget?.currency ||
        oldWidget.budget?.limit != widget.budget?.limit ||
        oldWidget.budget?.spent != widget.budget?.spent ||
        oldWidget.currency != widget.currency ||
        oldWidget.priceRevision != widget.priceRevision ||
        !identical(oldWidget.ingredientPrices, widget.ingredientPrices) ||
        oldWidget.recipes.map((r) => '${r.id}:${r.servings}').join() !=
            widget.recipes.map((r) => '${r.id}:${r.servings}').join()) {
      _request = _load();
    }
  }

  void _details(RecipeCost cost) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.cream,
    builder: (_) => RecipeCostSheet(
      cost: cost,
      budget: _displayBudget,
      manualPrices: widget.ingredientPrices ?? const {},
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final allowance = widget.budget == null
        ? null
        : mealAllowanceCents(widget.budget!, widget.now);
    return Column(
      key: const ValueKey('budget-recipes-preview'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.budgetRecipeTitle,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          widget.budget == null
              ? MigaUiCopy.choose(
                  context,
                  'Configura tu presupuesto en Perfil para personalizar las recetas.',
                  'Set a budget in Profile to personalize these recipes.',
                )
              : MigaUiCopy.budgetSubtitle(context),
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<RecipeCost>>(
          future: widget.costFor == null ? _request : null,
          builder: (context, snapshot) {
            if (widget.costFor != null) {
              snapshot = AsyncSnapshot.withData(
                ConnectionState.done,
                widget.recipes.map(widget.costFor!).toList(),
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              // Two photo-sized skeletons keep the page stable while fetching.
              return Row(
                children: [
                  for (var i = 0; i < 2; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: .88,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6ECD9),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.olive,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }
            if (snapshot.hasError) {
              return Text(l.groceryEstimateUnavailable);
            }
            final allCosts = List<RecipeCost>.of(snapshot.data ?? []);
            if (allCosts.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    MigaUiCopy.choose(
                      context,
                      'No encontramos recetas con tus preferencias actuales.',
                      'No recipes match your current preferences.',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    key: const ValueKey('budget-see-all'),
                    onPressed: widget.onSeeAll,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(MigaUiCopy.getMore(context)),
                  ),
                ],
              );
            }
            allCosts.sort((a, b) {
              // Only a real, configured budget can establish affordability.
              if (allowance != null) {
                final fit = (b.fits(allowance) ? 1 : 0).compareTo(
                  a.fits(allowance) ? 1 : 0,
                );
                if (fit != 0) return fit;
              }
              if (a.complete != b.complete) return a.complete ? -1 : 1;
              // Consistent ordering makes the preview stable across rebuilds.
              final amount = a.subtotalCents.compareTo(b.subtotalCents);
              return amount != 0
                  ? amount
                  : a.recipe.imageIndex.compareTo(b.recipe.imageIndex);
            });
            final fits = allowance == null
                ? <RecipeCost>[]
                : allCosts.where((cost) => cost.fits(allowance)).toList();
            final featured = <RecipeCost>[
              if (allowance != null) ...fits.take(2),
            ];
            // If not enough confirmed matches exist, show clearly unconfirmed
            // suggestions rather than an empty screen. Never label these as
            // fitting the user's budget.
            for (final candidate in allCosts) {
              if (featured.length >= 2) break;
              if (!featured.contains(candidate)) featured.add(candidate);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.budget != null && fits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      l.budgetNoConfirmedFit,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < featured.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _BudgetRecipeTile(
                          key: ValueKey(
                            'budget-recipe-${featured[i].recipe.id}',
                          ),
                          cost: featured[i],
                          pricing: widget.pricing,
                          budget: _displayBudget,
                          onOpen: () => widget.onRecipe(featured[i].recipe),
                          onCosts: () => _details(featured[i]),
                          favorite: widget.favorites.contains(
                            featured[i].recipe.id,
                          ),
                          onFavorite: widget.onFavorite == null
                              ? null
                              : () => widget.onFavorite!(featured[i].recipe.id),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 46,
                  child: FilledButton.icon(
                    key: const ValueKey('budget-see-all'),
                    onPressed: widget.onSeeAll,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFDDE9C5),
                      foregroundColor: AppColors.ink,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    label: Text(MigaUiCopy.getMore(context)),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    iconAlignment: IconAlignment.end,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// A photo-first, two-column card like the selected Miga UI reference.
/// The money badge represents the ingredients required for the WHOLE recipe.
class _BudgetRecipeTile extends StatelessWidget {
  const _BudgetRecipeTile({
    super.key,
    required this.cost,
    this.pricing = false,
    required this.budget,
    required this.onOpen,
    required this.onCosts,
    required this.favorite,
    required this.onFavorite,
  });

  final RecipeCost cost;
  final bool pricing;
  final WeeklyBudget budget;
  final VoidCallback onOpen;
  final VoidCallback onCosts;
  final bool favorite;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: const Color(0xFF4D5D3E),
        child: InkWell(
          onTap: onOpen,
          child: AspectRatio(
            aspectRatio: 0.88,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RecipeImage(index: cost.recipe.imageIndex),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, .46, 1],
                      colors: [
                        Color(0x33000000),
                        Colors.transparent,
                        Color(0xDE0A180B),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 43,
                  top: 8,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      color: const Color(0xFFE7F0D9),
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        key: ValueKey('budget-cost-${cost.recipe.id}'),
                        borderRadius: BorderRadius.circular(22),
                        onTap: onCosts,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: Text(
                            cost.complete
                                ? '≈ ${budget.format(cost.subtotalCents / 100)}'
                                : pricing
                                ? l.groceryEstimating
                                : MigaUiCopy.incompletePrices(
                                    context,
                                    cost.ingredients
                                        .where((i) => i.cents != null)
                                        .length,
                                    cost.ingredients.length,
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.olive,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (onFavorite != null)
                  Positioned(
                    right: 3,
                    top: 3,
                    child: IconButton(
                      key: ValueKey('budget-favorite-${cost.recipe.id}'),
                      tooltip: favorite ? l.favoriteRemove : l.favoriteAdd,
                      onPressed: onFavorite,
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0x2F000000),
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                      icon: FavoriteHeartIcon(
                        favorite: favorite,
                        inactiveColor: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 11,
                  left: 11,
                  right: 9,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cost.recipe.contentFor(language).title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          height: 1.15,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 10,
                        runSpacing: 3,
                        children: [
                          _SmallInfo(
                            Icons.schedule_outlined,
                            l.recipeMinutes(cost.recipe.minutes),
                          ),
                          _SmallInfo(
                            Icons.restaurant_outlined,
                            '${cost.recipe.servings}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  const _SmallInfo(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Colors.white, size: 13),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
    ],
  );
}
