import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'home_controller.dart';
import 'home_header.dart';
import 'home_hero_carousel.dart';
import 'home_quick_actions.dart';
import 'home_week.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.controller,
    required this.onProfile,
    required this.onPlan,
    required this.onEditMeal,
    required this.onRecipe,
    required this.onBudget,
    required this.onGroceries,
    required this.onStores,
  });

  final HomeController controller;
  final VoidCallback onProfile;
  final VoidCallback onPlan;
  final VoidCallback onEditMeal;
  final VoidCallback onRecipe;
  final VoidCallback onBudget;
  final VoidCallback onGroceries;
  final VoidCallback onStores;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = controller.canEdit;
    return ListView(
      key: const PageStorageKey('home-dashboard'),
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
      children: [
        HomeHeader(onProfile: onProfile),
        const SizedBox(height: 22),
        if (controller.loading || controller.saving)
          const LinearProgressIndicator(),
        if (controller.loadFailed) ...[
          Text(l10n.homeLoadError, textAlign: TextAlign.center),
          TextButton(onPressed: controller.load, child: Text(l10n.homeRetry)),
        ],
        HomeHeroCarousel(
          selectedDate: controller.selectedDate,
          slot: controller.selectedSlot,
          meal: controller.mealFor(
            controller.selectedDate,
            controller.selectedSlot,
          ),
          budget: controller.budget,
          onSlot: controller.selectSlot,
          onEditMeal: enabled ? onEditMeal : null,
          onRecipe: enabled ? onRecipe : null,
          onBudget: enabled ? onBudget : null,
        ),
        const SizedBox(height: 12),
        HomeWeek(
          today: controller.today,
          selectedDate: controller.selectedDate,
          onSelected: controller.selectDate,
          hasMeals: controller.hasMeals,
          onViewPlan: onPlan,
        ),
        const SizedBox(height: 24),
        HomeQuickActions(
          pendingItems: controller.pendingGroceries,
          onGroceries: enabled ? onGroceries : null,
          onStores: onStores,
        ),
      ],
    );
  }
}
