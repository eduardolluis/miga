import '../../../support/recipe_catalog.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miga/features/home/application/home_controller.dart';
import 'package:miga/features/home/data/local_home_details_store.dart';
import 'package:miga/features/home/presentation/home_screen.dart';
import 'package:miga/features/meal_plan/data/local_meal_plan_store.dart';
import 'package:miga/l10n/app_localizations.dart';

void main() {
  testWidgets('Home displays recipes even when Weekly Budget is not set', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = HomeController(
      recipeRepository: RecipeCatalog.repository(),
      today: DateTime(2026, 10, 31, 20),
      planStore: LocalMealPlanStore('home-empty-budget'),
      detailsStore: LocalHomeDetailsStore('home-empty-budget'),
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.budget, isNull);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeScreen(
            controller: controller,
            userName: null,
            onProfile: () {},
            onPlan: () {},
            onEditMeal: () {},
            onRecipe: (_) {},
            onViewBudgetRecipes: () {},
            onPlanRecipe: (_) {},
            onBudget: () {},
            onGroceries: () {},
            onStores: () {},
            onPro: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The Home list can extend below the fold on a real iPhone.
    await tester.drag(
      find.byKey(const PageStorageKey('home-dashboard')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('budget-recipes-preview')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('budget-see-all')), findsOneWidget);
    // The Home dashboard must continue below recipes with the shortcuts.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('home-quick-actions')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-quick-pantry')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-quick-cheaper')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-quick-surprise')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-quick-generate')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
