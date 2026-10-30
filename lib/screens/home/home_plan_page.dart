import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import 'home_controller.dart';
import 'home_meal_card.dart';
import 'meal_slot.dart';

class HomePlanPage extends StatelessWidget {
  const HomePlanPage({
    super.key,
    required this.controller,
    required this.onEditMeal,
  });
  final HomeController controller;
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
          l10n.homeMealsPlanned(controller.mealCount),
          style: const TextStyle(
            color: AppColors.olive,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        if (controller.loading)
          const Center(child: CircularProgressIndicator()),
        if (controller.loadFailed) ...[
          Text(l10n.homeLoadError),
          TextButton(onPressed: controller.load, child: Text(l10n.homeRetry)),
        ] else if (!controller.loading)
          for (final date in controller.week) ...[
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
              HomeMealCard(
                slot: slot,
                meal: controller.mealFor(date, slot),
                onTap: controller.canEdit ? () => onEditMeal(date, slot) : null,
              ),
            const SizedBox(height: 14),
          ],
      ],
    );
  }
}
