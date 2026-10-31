import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/home/presentation/widgets/recipe_cost_sheet.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_image.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/l10n/app_localizations.dart';

class BudgetRecipeSuggestions extends StatefulWidget {
  const BudgetRecipeSuggestions({
    super.key,
    required this.budget,
    required this.now,
    required this.recipes,
    required this.onRecipe,
    this.estimate,
  });
  final WeeklyBudget budget;
  final DateTime now;
  final List<Recipe> recipes;
  final ValueChanged<Recipe> onRecipe;
  final Future<List<RecipeCost>> Function(List<Recipe>)? estimate;

  @override
  State<BudgetRecipeSuggestions> createState() =>
      _BudgetRecipeSuggestionsState();
}

class _BudgetRecipeSuggestionsState extends State<BudgetRecipeSuggestions> {
  final _estimator = RecipeCostEstimator();
  late Future<List<RecipeCost>> _request = _load();
  Future<List<RecipeCost>> _load() =>
      widget.budget.currency != 'DOP' && widget.estimate == null
      ? Future.value([])
      : (widget.estimate ?? _estimator.estimate)(widget.recipes);

  @override
  void didUpdateWidget(BudgetRecipeSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipes.map((r) => r.id).join() !=
            widget.recipes.map((r) => r.id).join() ||
        oldWidget.budget.currency != widget.budget.currency ||
        oldWidget.estimate != widget.estimate ||
        oldWidget.recipes.map((r) => r.servings).join(',') !=
            widget.recipes.map((r) => r.servings).join(',')) {
      _request = _load();
    }
  }

  void _details(RecipeCost cost) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.cream,
      builder: (_) => RecipeCostSheet(cost: cost, budget: widget.budget),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final allowance = mealAllowanceCents(widget.budget, widget.now);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEDDF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.budgetRecipeTitle,
            style: const TextStyle(fontFamily: 'LiberationSerif', fontSize: 23),
          ),
          const SizedBox(height: 8),
          if (widget.budget.currency != 'DOP' && widget.estimate == null)
            Text(l10n.budgetRecipeCurrency)
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEFDF9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.budgetMealTarget,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.budget.format(allowance / 100),
                    style: const TextStyle(
                      color: AppColors.olive,
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.budget.format(math.max(0.0, widget.budget.limit - widget.budget.spent))} ÷ ${remainingMealSlots(widget.now)} = ${widget.budget.format(allowance / 100)}',
                    style: const TextStyle(
                      color: AppColors.olive,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.budgetTargetNote,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FutureBuilder<List<RecipeCost>>(
              future: _request,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Column(
                    children: [
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(l10n.groceryEstimating),
                    ],
                  );
                }
                if (snapshot.hasError || (snapshot.data ?? []).isEmpty) {
                  return Text(l10n.groceryEstimateUnavailable);
                }
                final costs = List<RecipeCost>.of(snapshot.data!);
                costs.sort((a, b) {
                  final fit = (b.fits(allowance) ? 1 : 0).compareTo(
                    a.fits(allowance) ? 1 : 0,
                  );
                  if (fit != 0) return fit;
                  if (a.complete != b.complete) return a.complete ? -1 : 1;
                  return a.subtotalCents.compareTo(b.subtotalCents);
                });
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!costs.any((c) => c.fits(allowance)))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(l10n.budgetNoConfirmedFit),
                      ),
                    for (final cost in costs)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEFDF9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 64,
                                    height: 76,
                                    child: RecipeImage(
                                      index: cost.recipe.imageIndex,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cost.recipe.contentFor(language).title,
                                        style: const TextStyle(
                                          fontFamily: 'LiberationSerif',
                                          fontSize: 21,
                                          height: 1.15,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${l10n.recipeMinutes(cost.recipe.minutes)} · ${l10n.recipeServings(cost.recipe.servings)}',
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 13,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (cost.complete) ...[
                              Text(
                                '${l10n.budgetRecipeTotal(widget.budget.format(cost.subtotalCents / 100), cost.recipe.servings)}  ·  ${l10n.recipeCostPerServing(widget.budget.format(cost.perServingCents / 100))}',
                                style: const TextStyle(
                                  color: AppColors.olive,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEBEDDF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    cost.fits(allowance)
                                        ? l10n.budgetRecipeFits
                                        : l10n.budgetRecipeOver,
                                    style: const TextStyle(
                                      color: AppColors.olive,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Text(
                                l10n.budgetPriceCoverage(
                                  cost.ingredients
                                      .where((l) => l.cents != null)
                                      .length,
                                  cost.ingredients.length,
                                ),
                                style: const TextStyle(
                                  color: AppColors.olive,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.budgetRecipePartial(
                                  cost.ingredients
                                      .where((l) => l.cents == null)
                                      .length,
                                ),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final actions = [
                                  OutlinedButton(
                                    onPressed: () => _details(cost),
                                    child: Text(l10n.budgetCostDetails),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        widget.onRecipe(cost.recipe),
                                    child: Text(l10n.homeViewRecipe),
                                  ),
                                ];
                                if (constraints.maxWidth < 320 ||
                                    MediaQuery.textScalerOf(context).scale(14) >
                                        20) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      actions[0],
                                      const SizedBox(height: 8),
                                      actions[1],
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(child: actions[0]),
                                    const SizedBox(width: 10),
                                    Expanded(child: actions[1]),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
