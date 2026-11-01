import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/meal_plan/presentation/widgets/meal_card.dart';
import 'package:miga/l10n/app_localizations.dart';
import 'package:miga/features/meal_plan/domain/plan_estimate.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';

class MealPlanPage extends StatelessWidget {
  const MealPlanPage({
    super.key,
    required this.week,
    required this.mealCount,
    required this.loading,
    required this.loadFailed,
    required this.canEdit,
    required this.mealFor,
    required this.onRetry,
    required this.onEditMeal,
    this.onCopyDay,
    this.onChooseRecipe,
    this.onMealAction,
    this.onAutoPlan,
    this.estimateFor,
    this.budget,
    this.pricing = false,
    this.currency = 'DOP',
  });
  final List<DateTime> week;
  final int mealCount;
  final bool loading;
  final bool loadFailed;
  final bool canEdit;
  final String? Function(DateTime date, MealSlot slot) mealFor;
  final VoidCallback onRetry;
  final void Function(DateTime date, MealSlot slot) onEditMeal;
  final void Function(DateTime fromDate)? onCopyDay;
  final void Function(DateTime, MealSlot)? onChooseRecipe;
  final void Function(DateTime, MealSlot, String)? onMealAction;
  final VoidCallback? onAutoPlan;
  final PlanEstimate Function([DateTime?])? estimateFor;
  final WeeklyBudget? budget;
  final bool pricing;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      key: const PageStorageKey('home-calendar'),
      padding: const EdgeInsets.all(22),
      children: [
        Text(
          l10n.homeCalendarTitle,
          style: const TextStyle(fontFamily: 'Georgia', fontSize: 32),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.homeCalendarSubtitle,
          style: const TextStyle(color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.homeMealsPlanned(mealCount),
          style: const TextStyle(
            color: AppColors.olive,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        if (onAutoPlan != null)
          FilledButton.tonalIcon(
            onPressed: onAutoPlan,
            icon: const Icon(Icons.auto_awesome),
            label: Text(l10n.autoPlanTitle),
          ),
        if (pricing) const LinearProgressIndicator(),
        if (estimateFor != null && mealCount > 0)
          _estimate(context, estimateFor!()),
        if (loading) const Center(child: CircularProgressIndicator()),
        if (loadFailed) ...[
          Text(l10n.homeLoadError),
          TextButton(onPressed: onRetry, child: Text(l10n.homeRetry)),
        ] else if (!loading) ...[
          if (mealCount == 0) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEFDF9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 32,
                    color: AppColors.olive,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.homeWeekEmpty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          for (final date in week) ...[
            if (estimateFor != null &&
                MealSlot.values.any((s) => mealFor(date, s) != null))
              _estimate(context, estimateFor!(date)),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      MaterialLocalizations.of(context).formatFullDate(date),
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 22,
                      ),
                    ),
                  ),
                  if (canEdit &&
                      onCopyDay != null &&
                      MealSlot.values.any((s) => mealFor(date, s) != null))
                    TextButton.icon(
                      onPressed: () => onCopyDay!(date),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(l10n.planCopyDay),
                    ),
                ],
              ),
            ),
            for (final slot in MealSlot.values)
              MealCard(
                slot: slot,
                meal: mealFor(date, slot),
                onTap: canEdit ? () => onEditMeal(date, slot) : null,
                onChooseRecipe: canEdit && onChooseRecipe != null
                    ? () => onChooseRecipe!(date, slot)
                    : null,
                onAction: canEdit && onMealAction != null
                    ? (action) => onMealAction!(date, slot, action)
                    : null,
              ),
            const SizedBox(height: 14),
          ],
        ],
      ],
    );
  }

  Widget _estimate(BuildContext context, PlanEstimate estimate) {
    final l = AppLocalizations.of(context)!;
    final money = WeeklyBudget(limit: 0, spent: 0, currency: currency);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l.planEstimateTitle}: ≈ ${money.format(estimate.subtotalCents / 100)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (!estimate.complete) Text(l.incompleteEstimate),
        ],
      ),
    );
  }
}
