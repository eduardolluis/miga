import 'package:flutter/material.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/l10n/app_localizations.dart';

class RecipeCostSheet extends StatelessWidget {
  const RecipeCostSheet({super.key, required this.cost, required this.budget});
  final RecipeCost cost;
  final WeeklyBudget budget;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final priced = cost.ingredients.where((line) => line.cents != null).length;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.budgetCostDetails,
                  style: const TextStyle(
                    fontFamily: 'LiberationSerif',
                    fontSize: 28,
                  ),
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cost.recipe.contentFor(language).title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EBDF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cost.complete
                      ? l10n.budgetRecipeEstimate
                      : l10n.budgetKnownSubtotal,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '≈ ${budget.format(cost.subtotalCents / 100)}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: AppColors.olive,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.recipeServings(cost.recipe.servings)}  ·  ${l10n.recipeCostPerServing(budget.format(cost.perServingCents / 100))}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (cost.recipe.nutrition != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.recipeNutrition(
                      cost.recipe.nutrition!.calories,
                      cost.recipe.nutrition!.proteinGrams,
                      cost.recipe.nutrition!.carbsGrams,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: cost.ingredients.isEmpty
                      ? 0
                      : priced / cost.ingredients.length,
                  borderRadius: BorderRadius.circular(6),
                  minHeight: 5,
                  color: AppColors.olive,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.budgetPriceCoverage(priced, cost.ingredients.length),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 12),
              leading: const Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: AppColors.olive,
              ),
              title: Text(
                l10n.budgetEstimateInfo,
                style: const TextStyle(fontSize: 14),
              ),
              children: [
                Text(
                  l10n.budgetCostNote,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.homeIngredients,
            style: const TextStyle(fontFamily: 'LiberationSerif', fontSize: 23),
          ),
          const SizedBox(height: 14),
          for (final line in cost.ingredients)
            _IngredientRow(line: line, budget: budget),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.line, required this.budget});
  final IngredientCost line;
  final WeeklyBudget budget;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final amount = line.amount.amount;
    final quantity = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toString();
    final unit = switch (line.amount.unit) {
      CostUnit.grams => 'g',
      CostUnit.milliliters => 'ml',
      CostUnit.pieces => l10n.budgetPieces,
    };
    final offer = line.offer;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFDF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 5,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Text(
              line.amount.ingredient.label(language),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 14,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '$quantity $unit',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    line.cents == null
                        ? l10n.groceryEstimateUnavailable
                        : '≈ ${budget.format(line.cents! / 100)}',
                    style: TextStyle(
                      color: line.cents == null
                          ? AppColors.muted
                          : AppColors.olive,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            children: [
              const Divider(height: 20, color: AppColors.line),
              if (offer != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      offer.product,
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.budgetPackPrice(
                        budget.format(offer.priceCents / 100),
                      ),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Text(
                          offer.store.label,
                          style: const TextStyle(
                            color: AppColors.olive,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          MaterialLocalizations.of(context)
                              .formatShortDate(offer.observedAt.toLocal()),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Text(
                  l10n.budgetRecipePartial(1),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
