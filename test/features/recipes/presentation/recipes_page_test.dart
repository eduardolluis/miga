import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/presentation/recipes_page.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_card.dart';
import 'package:miga/l10n/app_localizations.dart';

Widget frame(
  String language, {
  int request = 0,
  int pantryRequest = 0,
  RecipeCost Function(Recipe)? costFor,
  WeeklyBudget? budget,
}) => MaterialApp(
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: RecipesPage(
      onOpenRecipe: (_) {},
      budgetFilterRequest: request,
      pantryFilterRequest: pantryRequest,
      costFor: costFor,
      budget: budget,
      now: DateTime(2026, 11, 1, 20),
    ),
  ),
);

RecipeCost priced(Recipe recipe) => RecipeCost(recipe, [
  for (final amount in RecipeAmounts.forRecipe(recipe))
    IngredientCost(amount, cents: 100),
]);

void main() {
  testWidgets('Recipes back arrow returns to Home', (tester) async {
    var returned = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RecipesPage(
            onOpenRecipe: (_) {},
            onBack: () => returned = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipes-back-home')));
    expect(returned, isTrue);
    expect(tester.takeException(), isNull);
  });
  for (final language in ['en', 'es']) {
    testWidgets('Catalog uses a photographic grid and search in $language', (
      tester,
    ) async {
      await tester.pumpWidget(frame(language));
      await tester.pumpAndSettle();
      expect(find.byType(RecipeCard), findsWidgets);
      expect(
        find.text(language == 'es' ? '54 recetas' : '54 recipes'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('recipe-search')),
        language == 'es' ? 'avena con manzana' : 'apple cinnamon',
      );
      await tester.pumpAndSettle();
      expect(
        find.text(language == 'es' ? '1 receta' : '1 recipe'),
        findsOneWidget,
      );
      expect(find.byType(RecipeCard), findsOneWidget);
    });
  }

  testWidgets(
    'A Home budget request selects Within budget, and can be cleared',
    (tester) async {
      const budget = WeeklyBudget(limit: 100000, spent: 0, currency: 'DOP');
      await tester.pumpWidget(frame('en', budget: budget, costFor: priced));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('within-budget-filter')), findsNothing);
      await tester.pumpWidget(
        frame('en', request: 1, budget: budget, costFor: priced),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('within-budget-filter')),
        findsOneWidget,
      );
      expect(find.text('Within budget'), findsOneWidget);
      final chip = tester.widget<InputChip>(
        find.byKey(const ValueKey('within-budget-filter')),
      );
      chip.onDeleted!();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('within-budget-filter')), findsNothing);
    },
  );

  testWidgets('Home See all without a budget does not apply an empty filter', (
    tester,
  ) async {
    const budget = WeeklyBudget(limit: 100000, spent: 0, currency: 'DOP');
    await tester.pumpWidget(
      frame('en', request: 1, budget: budget, costFor: priced),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('within-budget-filter')), findsOneWidget);
    await tester.pumpWidget(frame('en', request: -2));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('within-budget-filter')), findsNothing);
    expect(find.byType(RecipeCard), findsWidgets);
  });

  testWidgets('Pantry shortcut activates pantry filter', (tester) async {
    await tester.pumpWidget(frame('en'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(frame('en', pantryRequest: 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pantry-filter')), findsOneWidget);
  });

  testWidgets('Ingredient totals appear, never a buyable price per serving', (
    tester,
  ) async {
    await tester.pumpWidget(
      frame(
        'en',
        budget: const WeeklyBudget(limit: 100000, spent: 0, currency: 'DOP'),
        costFor: priced,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('per serving'), findsNothing);
    expect(find.byType(RecipeCard), findsWidgets);
  });
}
