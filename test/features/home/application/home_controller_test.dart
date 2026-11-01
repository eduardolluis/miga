import '../../../support/recipe_catalog.dart';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/home/application/home_controller.dart';
import 'package:miga/features/home/data/local_home_details_store.dart';
import 'package:miga/features/meal_plan/data/local_meal_plan_store.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';

void main() {
  test(
    'Existing v1 data survives the folder and model reorganization',
    () async {
      SharedPreferences.setMockInitialValues({
        'miga.meals.v1.user': '{"2026-02-04:lunch":"Arroz"}',
        'miga.home.v1.user': '{"budgets":{"2026-2-2":{"limit":4000,"spent":500,"currency":"DOP"}},"groceries":[{"name":"Pan","checked":false}]}',
      });
      final controller = HomeController(
        recipeRepository: RecipeCatalog.repository(),
        today: DateTime(2026, 2, 4),
        planStore: LocalMealPlanStore('user'),
        detailsStore: LocalHomeDetailsStore('user'),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.loadFailed, isFalse);
      expect(controller.mealFor(DateTime(2026, 2, 4), MealSlot.lunch), 'Arroz');
      expect(controller.mealCount, 1);
      expect(controller.budget!.spent, 500);
      expect(controller.pendingGroceries, 1);
      expect(
        await controller.saveBudget(
          const WeeklyBudget(limit: 4500, spent: 600, currency: 'DOP'),
        ),
        isTrue,
      );

      final preferences = await SharedPreferences.getInstance();
      final saved = jsonDecode(
        preferences.getString('miga.home.v1.user')!,
      ) as Map<String, dynamic>;
      expect((saved['budgets'] as Map<String, dynamic>).keys, ['2026-2-2']);
      expect((saved['groceries'] as List<dynamic>).single['name'], 'Pan');
      expect(
        preferences.getString('miga.meals.v1.user'),
        '{"2026-02-04:lunch":"Arroz"}',
      );
    },
  );
  test(
    'Automatic suggestions follow the clock and preserve a manual selection',
    () async {
      SharedPreferences.setMockInitialValues({});
      final controller = HomeController(
        recipeRepository: RecipeCatalog.repository(),
        today: DateTime(2026, 10, 30, 10, 59),
        planStore: LocalMealPlanStore('clock'),
        detailsStore: LocalHomeDetailsStore('clock'),
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.selectedSlot, MealSlot.breakfast);
      controller.syncTime(DateTime(2026, 10, 30, 11));
      expect(controller.selectedSlot, MealSlot.lunch);
      controller.syncTime(DateTime(2026, 10, 30, 17));
      expect(controller.selectedSlot, MealSlot.dinner);
      controller.selectSlot(MealSlot.breakfast);
      controller.syncTime(DateTime(2026, 10, 30, 20));
      expect(controller.selectedSlot, MealSlot.breakfast);
      controller.useCurrentSlot();
      expect(controller.selectedSlot, MealSlot.dinner);
      controller.syncTime(DateTime(2026, 10, 31, 5));
      expect(controller.selectedSlot, MealSlot.breakfast);
      expect(controller.selectedDate, DateTime(2026, 10, 31));
    },
  );
}
