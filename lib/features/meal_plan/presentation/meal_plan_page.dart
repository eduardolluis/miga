import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/meal_plan/presentation/widgets/meal_card.dart';
import 'package:miga/l10n/app_localizations.dart';

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
  });
  final List<DateTime> week;
  final int mealCount;
  final bool loading;
  final bool loadFailed;
  final bool canEdit;
  final String? Function(DateTime date, MealSlot slot) mealFor;
  final VoidCallback onRetry;
  final void Function(DateTime date, MealSlot slot) onEditMeal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      key: const PageStorageKey('home-calendar'),
      padding: const EdgeInsets.all(22),
      children: [
        Text(
          l10n.homeCalendarTitle,
          style: const TextStyle(fontFamily: 'LiberationSerif', fontSize: 32),
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
        if (loading) const Center(child: CircularProgressIndicator()),
        if (loadFailed) ...[
          Text(l10n.homeLoadError),
          TextButton(onPressed: onRetry, child: Text(l10n.homeRetry)),
        ] else if (!loading)
          for (final date in week) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 14),
              child: Text(
                MaterialLocalizations.of(context).formatFullDate(date),
                style: const TextStyle(
                  fontFamily: 'LiberationSerif',
                  fontSize: 22,
                ),
              ),
            ),
            for (final slot in MealSlot.values)
              MealCard(
                slot: slot,
                meal: mealFor(date, slot),
                onTap: canEdit ? () => onEditMeal(date, slot) : null,
              ),
            const SizedBox(height: 14),
          ],
      ],
    );
  }
}
