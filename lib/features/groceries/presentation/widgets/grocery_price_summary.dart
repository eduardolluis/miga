import 'package:flutter/material.dart';
import 'package:miga/core/ui/miga_skeleton.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
import 'package:miga/l10n/app_localizations.dart';

String groceryPackageLabel(GroceryItem item, AppLocalizations l) {
  final offer = item.offer;
  final pack = offer == null
      ? null
      : RecipeCostEstimator.packageForOffer(offer);
  if (pack == null) return l.groceryPackages(item.quantity);
  final amount = pack.$1.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  final unit = switch (pack.$2) {
    CostUnit.grams => 'g',
    CostUnit.milliliters => 'ml',
    CostUnit.pieces => l.budgetPieces,
  };
  return '${item.quantity} × $amount $unit';
}

String? groceryEggUnitPrice(GroceryItem item, AppLocalizations l) {
  if (item.ingredientForPricing != RecipeIngredient.eggs ||
      item.offer == null) {
    return null;
  }
  final pack = RecipeCostEstimator.packageForOffer(item.offer!);
  if (pack == null || pack.$2 != CostUnit.pieces || pack.$1 <= 1) return null;
  return l.groceryPerEgg(
    item.formatCents((item.offer!.priceCents / pack.$1).round()),
  );
}

class GroceryPriceSummary extends StatelessWidget {
  const GroceryPriceSummary({
    super.key,
    required this.items,
    required this.currency,
    this.loading = false,
  });
  final List<GroceryItem> items;
  final String currency;
  final bool loading;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final totals = GroceryTotals(items, currency, includeBudgetEstimates: true);
    final checked = items.where((item) => item.checked).length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE7EDDC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.groceryEstimatedTotal,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 5),
          if (loading && totals.priced == 0)
            Semantics(
              label: l.groceryEstimating,
              child: const Align(
                alignment: Alignment.centerLeft,
                child: MigaSkeleton(child: SkeletonBox(width: 150, height: 34)),
              ),
            )
          else
            Text(
              totals.priced == 0
                  ? '—'
                  : '${totals.estimated > 0 ? '≈ ' : ''}${GroceryItem('', currency: currency).formatCents(totals.subtotalCents)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          if (totals.missing > 0) ...[
            const SizedBox(height: 5),
            Text(
              loading
                  ? l.groceryEstimating
                  : l.groceryPricesMissing(totals.missing),
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
          if (totals.estimated > 0) ...[
            const SizedBox(height: 5),
            Text(
              l.groceryEstimateNote,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            l.groceryCartProgress(checked, items.length),
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(end: items.isEmpty ? 0 : checked / items.length),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 240),
            builder: (_, value, _) => LinearProgressIndicator(
              value: value,
              color: AppColors.olive,
              backgroundColor: Colors.white,
              minHeight: 6,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}
