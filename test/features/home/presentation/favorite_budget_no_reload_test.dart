import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/home/presentation/widgets/budget_recipe_suggestions.dart';

import '../../../support/recipe_catalog.dart';

import 'package:miga/l10n/app_localizations.dart';

void main() {
  testWidgets('Liking does not restart the budget photo grid loading state', (
    tester,
  ) async {
    final recipe = RecipeCatalog.all.first;
    final cost = RecipeCost(recipe, [
      for (final amount in RecipeAmounts.forRecipe(recipe))
        IngredientCost(amount, cents: 100),
    ]);
    var estimations = 0;
    Widget frame(Set<String> favorites) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: BudgetRecipeSuggestions(
            budget: const WeeklyBudget(
              limit: 100000,
              spent: 0,
              currency: 'DOP',
            ),
            now: DateTime(2026, 10, 31, 13),
            recipes: [recipe],
            favorites: favorites,
            // Flutter recreates this closure on each parent rebuild.
            estimate: (_) async {
              estimations++;
              return [cost];
            },
            onRecipe: (_) {},
            onFavorite: (_) {},
          ),
        ),
      ),
    );

    await tester.pumpWidget(frame({}));
    await tester.pumpAndSettle();
    expect(estimations, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpWidget(frame({recipe.id}));
    await tester.pumpAndSettle();
    expect(
      estimations,
      1,
      reason: 'A favorite-only update must not recalculate recipes',
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });
}
