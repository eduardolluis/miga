import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';

import '../../../support/recipe_catalog.dart';

import 'package:miga/features/recipes/presentation/sheets/recipe_details_sheet.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_nutrition_panel.dart';
import 'package:miga/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'Back button stays visible and closes the recipe after scrolling',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    showRecipeDetails(context, RecipeCatalog.all.first),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final back = find.byKey(const ValueKey('recipe-back'));
      expect(back.hitTestable(), findsOneWidget);
      await tester.drag(find.byType(ListView).last, const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(back.hitTestable(), findsOneWidget);
      expect(tester.getTopLeft(back).dy, lessThan(100));
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(back, findsNothing);
      expect(find.text('Open').hitTestable(), findsOneWidget);
    },
  );

  testWidgets(
    'Missing recipe prices refresh automatically without an Add price action',
    (tester) async {
      final recipe = RecipeCatalog.all.first;
      var current = RecipeCost(recipe, [
        for (final amount in RecipeAmounts.forRecipe(recipe))
          IngredientCost(amount),
      ]);
      var requests = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Open'),
                onPressed: () => showRecipeDetails(
                  context,
                  recipe,
                  costFor: (_) => current,
                  onRefreshPrices: (recipe) async {
                    requests++;
                    current = RecipeCost(recipe, [
                      for (final amount in RecipeAmounts.forRecipe(recipe))
                        IngredientCost(amount, cents: 10000, purchaseCount: 1),
                    ]);
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(find.text('Add price'), findsNothing);
      expect(find.text('Añadir precio'), findsNothing);
      expect(current.ingredients.every((line) => line.cents == 10000), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  for (final language in ['en', 'es']) {
    testWidgets('Recipe nutrition wraps on a narrow screen in $language', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    showRecipeDetails(context, RecipeCatalog.all.first),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final nutritionTab = find.byKey(const ValueKey('recipe-tab-2'));
      await tester.scrollUntilVisible(nutritionTab, 180);
      await tester.pumpAndSettle();
      await tester.tap(nutritionTab);
      await tester.pumpAndSettle();
      expect(find.byType(RecipeNutritionPanel), findsOneWidget);
      await tester.ensureVisible(find.byType(RecipeNutritionPanel));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
