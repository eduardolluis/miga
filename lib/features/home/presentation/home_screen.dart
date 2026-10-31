import 'package:flutter/material.dart';
import 'package:miga/features/home/presentation/widgets/budget_recipe_suggestions.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/home/application/home_controller.dart';
import 'package:miga/features/home/presentation/widgets/home_budget_summary.dart';
import 'package:miga/features/home/presentation/widgets/home_header.dart';
import 'package:miga/features/home/presentation/widgets/home_hero_carousel.dart';
import 'package:miga/features/home/presentation/widgets/home_quick_actions.dart';
import 'package:miga/features/home/presentation/widgets/home_week.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/meal_plan/presentation/meal_slot_presentation.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/l10n/app_localizations.dart';
import 'package:miga/features/pro/presentation/widgets/pro_offer_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.userName,
    required this.onProfile,
    required this.onPlan,
    required this.onEditMeal,
    required this.onRecipe,
    required this.onPlanRecipe,
    required this.onBudget,
    required this.onGroceries,
    required this.onStores,
    required this.onPro,
  });
  final HomeController controller;
  final String? userName;
  final VoidCallback onProfile;
  final VoidCallback onPlan;
  final VoidCallback onEditMeal;
  final ValueChanged<Recipe> onRecipe;
  final ValueChanged<Recipe> onPlanRecipe;
  final VoidCallback onBudget;
  final VoidCallback onGroceries;
  final VoidCallback onStores;
  final VoidCallback onPro;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = controller.canEdit;
    final title = switch (controller.selectedSlot) {
      MealSlot.breakfast => l10n.homeIdeasBreakfast,
      MealSlot.lunch => l10n.homeIdeasLunch,
      MealSlot.dinner => l10n.homeIdeasDinner,
    };
    return ListView(
      key: const PageStorageKey('home-dashboard'),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      children: [
        HomeHeader(onProfile: onProfile, now: controller.now, name: userName),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'LiberationSerif',
                  fontSize: 25,
                  height: 1.1,
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: l10n.homeChangeMeal,
              onSelected: (value) => value == 'auto'
                  ? controller.useCurrentSlot()
                  : controller.selectSlot(MealSlot.values.byName(value)),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'auto', child: Text(l10n.homeUseTime)),
                for (final slot in MealSlot.values)
                  PopupMenuItem(
                    value: slot.name,
                    child: Text(slot.label(l10n)),
                  ),
              ],
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EBDF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 22,
                  color: AppColors.olive,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          controller.automaticSlot ? l10n.homeIdeasNow : l10n.homeIdeasManual,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        if (controller.loading || controller.saving)
          const LinearProgressIndicator(),
        if (controller.loadFailed) ...[
          Text(l10n.homeLoadError, textAlign: TextAlign.center),
          TextButton(onPressed: controller.load, child: Text(l10n.homeRetry)),
        ],
        HomeHeroCarousel(
          recipes: controller.recommendations(controller.selectedSlot),
          onOpenRecipe: enabled ? onRecipe : null,
          onPlanRecipe: enabled ? onPlanRecipe : null,
        ),
        const SizedBox(height: 20),
        Text(
          l10n.todayMealsTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        for (final slot in MealSlot.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${slot.label(l10n)} · ${controller.mealFor(controller.today, slot) ?? l10n.homeEmptyMeal}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        const SizedBox(height: 16),
        HomeWeek(
          today: controller.today,
          selectedDate: controller.selectedDate,
          onSelected: controller.selectDate,
          hasMeals: controller.hasMeals,
          onViewPlan: onPlan,
          mealCount: controller.mealCount,
          remainingBudget: controller.budget?.format(
            controller.budget!.limit - controller.budget!.spent,
          ),
          todayMeal: controller.mealFor(
            controller.today,
            controller.selectedSlot,
          ),
          meal: controller.mealFor(
            controller.selectedDate,
            controller.selectedSlot,
          ),
          slotLabel: controller.selectedSlot.label(l10n),
          onEditMeal: enabled ? onEditMeal : null,
        ),
        const SizedBox(height: 16),
        HomeBudgetSummary(
          budget: controller.budget,
          groceries: controller.details.groceries,
          onTap: enabled ? onBudget : null,
          onAddPrices: enabled ? onGroceries : null,
        ),
        if (controller.budget != null && controller.budgetCurrencyMatches) ...[
          const SizedBox(height: 16),
          BudgetRecipeSuggestions(
            budget: controller.budget!,
            now: controller.now,
            recipes: controller.recommendations(controller.selectedSlot),
            estimate: (recipes) async =>
                recipes.map(controller.costFor).toList(),
            onRecipe: onRecipe,
          ),
        ],
        const SizedBox(height: 16),
        HomeQuickActions(
          pendingItems: controller.pendingGroceries,
          onGroceries: enabled ? onGroceries : null,
          onStores: onStores,
        ),
        const SizedBox(height: 24),
        ProOfferCard(onOpen: onPro),
      ],
    );
  }
}
