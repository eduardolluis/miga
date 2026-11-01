import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miga/features/home/application/home_controller.dart';
import 'package:miga/features/home/data/local_home_details_store.dart';
import 'package:miga/features/meal_plan/data/local_meal_plan_store.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';

import '../../../support/recipe_catalog.dart';

import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
import 'package:miga/features/pantry/domain/pantry_item.dart';
import 'package:miga/features/profile/domain/household_preferences.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';

void main() {
  late HomeController controller;
  final oats = RecipeCatalog.all.first;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    controller = HomeController(
      recipeRepository: RecipeCatalog.repository(),
      today: DateTime(2026, 10, 30, 8),
      planStore: LocalMealPlanStore('workflow'),
      detailsStore: LocalHomeDetailsStore('workflow'),
    );
    await controller.load();
  });
  tearDown(() => controller.dispose());

  test(
    'Recipe identity and portions survive reload and language changes',
    () async {
      expect(
        await controller.saveRecipe(
          controller.today,
          MealSlot.breakfast,
          oats.withServings(4),
        ),
        isTrue,
      );
      await controller.load();
      controller.setLanguage('en');
      expect(
        controller.mealFor(controller.today, MealSlot.breakfast),
        oats.en.title,
      );
      expect(
        controller.recipeFor(controller.today, MealSlot.breakfast)!.servings,
        4,
      );
      controller.setLanguage('es');
      expect(
        controller.mealFor(controller.today, MealSlot.breakfast),
        oats.es.title,
      );
    },
  );

  test(
    'Repeated recipes sum physical amounts and subtract pantry once',
    () async {
      await controller.saveRecipe(
        controller.today,
        MealSlot.breakfast,
        oats.withServings(4),
      );
      await controller.saveRecipe(
        controller.week.last,
        MealSlot.breakfast,
        oats,
      );
      await controller.savePantry([
        const PantryItem(RecipeIngredient.oats, 100, CostUnit.grams),
      ]);
      final generated = controller.generateGroceriesFromPlannedMeals(
        languageCode: 'en',
      );
      final item = generated.singleWhere((i) => i.ingredientId == 'oats');
      expect(item.requiredAmount, 140); // 160g + 80g - 100g.
      expect(item.requiredUnit, CostUnit.grams);
      expect(generated.where((i) => i.ingredientId == 'oats'), hasLength(1));
    },
  );

  test('Linked groceries follow move, delete and undo without changing actual spending', () async {
    await controller.saveBudget(
      const WeeklyBudget(limit: 3000, spent: 250, currency: 'DOP'),
    );
    await controller.setGrocerySync(true);
    await controller.saveRecipe(controller.today, MealSlot.breakfast, oats);
    expect(controller.details.groceries, isNotEmpty);
    await controller.transferMeal(controller.today, MealSlot.breakfast, [
      (controller.week.last, MealSlot.breakfast),
    ], move: true);
    expect(controller.mealFor(controller.today, MealSlot.breakfast), isNull);
    expect(
      controller.details.groceries
          .singleWhere((i) => i.ingredientId == 'oats')
          .requiredAmount,
      80,
    );
    await controller.saveMeal(controller.week.last, MealSlot.breakfast, '');
    expect(controller.details.groceries, isEmpty);
    expect(await controller.undo(), isTrue);
    expect(controller.details.groceries, isNotEmpty);
    expect(controller.budget!.spent, 250);
  });

  test('Manual ingredient prices buy complete reference units', () async {
    await controller.saveIngredientPrice(RecipeIngredient.oats, 10000);
    final two = controller.costFor(oats),
        four = controller.costFor(oats.withServings(4));
    expect(two.subtotalCents, 10000);
    expect(four.subtotalCents, 10000);
    expect(four.perServingCents, 2500);
    expect(four.complete, isFalse);
  });

  test('Automatic plan respects budget, household size, restrictions and existing meals', () async {
    await controller.saveBudget(
      const WeeklyBudget(limit: 5000, spent: 200, currency: 'DOP'),
    );
    await controller.savePreferences(
      const HouseholdPreferences(
        members: 4,
        restrictions: {DietaryRestriction.vegetarian},
      ),
    );
    await controller.savePrices({
      for (final ingredient in RecipeIngredient.values)
        'DOP:${ingredient.name}': 100,
    });
    await controller.saveRecipe(
      controller.week.last,
      MealSlot.dinner,
      RecipeCatalog.all.last.withServings(4),
    );
    final previous = {...controller.meals};
    final proposal = controller.automaticPlan();
    for (final entry in previous.entries) {
      expect(proposal[entry.key], entry.value);
    }
    expect(proposal.length, greaterThan(previous.length));
    await controller.applyPlan(proposal);
    for (final date in controller.week) {
      for (final slot in MealSlot.values) {
        final recipe = controller.recipeFor(date, slot);
        if (recipe == null) continue;
        expect(controller.preferences.allows(recipe), isTrue);
        expect(recipe.servings, 4);
      }
    }
    expect(controller.estimateFor().complete, isTrue);
    expect(controller.estimateFor().subtotalCents, lessThanOrEqualTo(480000));
    expect(controller.details.syncGroceries, isTrue);
  });

  test('Unknown prices and conflicting currencies cannot produce a confirmed budget plan', () async {
    await controller.saveBudget(
      const WeeklyBudget(limit: 5000, spent: 0, currency: 'DOP'),
    );
    expect(controller.automaticPlan(), isEmpty);
    await controller.savePrices({
      for (final ingredient in RecipeIngredient.values)
        'DOP:${ingredient.name}': 100,
    });
    await controller.savePreferences(
      const HouseholdPreferences(currency: 'USD'),
    );
    expect(controller.automaticPlan(), isEmpty);
    expect(controller.costFor(oats).complete, isFalse);
  });
}
