import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/l10n/app_localizations.dart';

class HomeBudgetSummary extends StatelessWidget {
  const HomeBudgetSummary({
    super.key,
    required this.budget,
    required this.onTap,
    this.onAddPrices,
    this.groceries = const [],
  });
  final WeeklyBudget? budget;
  final VoidCallback? onTap;
  final VoidCallback? onAddPrices;
  final List<GroceryItem> groceries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = budget;
    final totals = GroceryTotals(groceries, value?.currency ?? 'DOP');
    final projected = (value?.spent ?? 0) + totals.subtotalCents / 100;
    return Material(
      color: const Color(0xFFFEFDF9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.olive,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.homeBudget,
                          style: const TextStyle(
                            fontFamily: 'LiberationSerif',
                            fontSize: 21,
                            height: 1.12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          value == null
                              ? l10n.homeSetBudget
                              : '${value.format(value.spent)} / ${value.format(value.limit)}',
                          style: const TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.chevron_right, color: AppColors.olive),
                ],
              ),
              if (totals.priced > 0 && value != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.groceryEstimate(value.format(totals.subtotalCents / 100)),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                Text(
                  projected > value.limit
                      ? l10n.budgetShoppingOver(value.format(projected - value.limit))
                      : l10n.budgetAfterShopping(value.format(value.limit - projected)),
                  style: const TextStyle(color: AppColors.olive, height: 1.5),
                ),
              ],
              if (totals.missing > 0) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.groceryPricesMissing(totals.missing),
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onAddPrices,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.groceryAddPrice),
                  ),
                ),
              ],
              if (value != null) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: (projected / value.limit).clamp(0.0, 1.0),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(6),
                  color: projected > value.limit ? const Color(0xFFA34F36) : AppColors.olive,
                  backgroundColor: const Color(0xFFE5E9DD),
                ),
                const SizedBox(height: 9),
                Text(
                  totals.missing > 0
                      ? l10n.budgetIncomplete
                      : projected > value.limit
                      ? l10n.homeBudgetOver
                      : l10n.homeBudgetOnTrack,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
