import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/home/presentation/widgets/budget_recipe_suggestions.dart';
import 'package:miga/features/home/presentation/widgets/recipe_cost_sheet.dart';
import 'package:miga/features/recipes/data/recipe_catalog.dart';
import 'package:miga/l10n/app_localizations.dart';

void main() {
  for (final language in ['en', 'es']) {
    testWidgets(
      'Ingredient breakdown fits narrow screens with large text in $language',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final recipe = RecipeCatalog.all.first;
        final cost = RecipeCost(recipe, [
          for (final amount in RecipeAmounts.values[recipe.id]!)
            IngredientCost(amount, cents: 1000),
        ]);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: RecipeCostSheet(
                cost: cost,
                budget: const WeeklyBudget(
                  limit: 1000,
                  spent: 0,
                  currency: 'DOP',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text(language == 'es' ? 'Avena' : 'Oats'),
          200,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Recommendations change with budget and never label partial costs as fitting',
    (tester) async {
      final recipe = RecipeCatalog.all.first;
      final priced = RecipeCost(recipe, [
        for (final amount in RecipeAmounts.values[recipe.id]!)
          IngredientCost(amount, cents: 1000),
      ]);
      final other = RecipeCatalog.all[1];
      final partial = RecipeCost(other, [
        for (final amount in RecipeAmounts.values[other.id]!)
          IngredientCost(amount),
      ]);
      Widget app(double limit) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BudgetRecipeSuggestions(
              budget: WeeklyBudget(limit: limit, spent: 0, currency: 'DOP'),
              now: DateTime(2026, 11, 1, 20),
              recipes: [recipe, other],
              onRecipe: (_) {},
              estimate: (_) async => [priced, partial],
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(100));
      await tester.pumpAndSettle();
      expect(find.text('Within your meal target'), findsOneWidget);
      expect(
        find.textContaining('Missing prices or package sizes'),
        findsOneWidget,
      );
      await tester.pumpWidget(app(10));
      await tester.pumpAndSettle();
      expect(find.text('Within your meal target'), findsNothing);
      expect(find.text('Above your meal target'), findsOneWidget);
      expect(find.textContaining('No fully priced meal fits'), findsOneWidget);
    },
  );
}
