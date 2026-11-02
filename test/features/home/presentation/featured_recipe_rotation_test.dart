import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/home/presentation/widgets/budget_recipe_suggestions.dart';
import 'package:miga/l10n/app_localizations.dart';

import '../../../support/recipe_catalog.dart';

void main() {
  testWidgets('The home preview changes recipes at the next launch cursor', (tester) async {
    final recipes = RecipeCatalog.all.take(5).toList();
    final costs = [
      for (final recipe in recipes)
        RecipeCost(recipe, [
          for (final ingredient in RecipeAmounts.forRecipe(recipe))
            IngredientCost(ingredient),
        ]),
    ];
    Widget frame(int rotation) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: BudgetRecipeSuggestions(
            rotationIndex: rotation,
            now: DateTime(2026, 11, 1),
            recipes: recipes,
            estimate: (_) async => costs,
            onRecipe: (_) {},
          ),
        ),
      ),
    );
    Future<Set<String>> visible() async => {
      for (final recipe in recipes)
        if (find.byKey(ValueKey('budget-recipe-${recipe.id}')).evaluate().isNotEmpty)
          recipe.id,
    };
    await tester.pumpWidget(frame(0));
    await tester.pumpAndSettle();
    final first = await visible();
    expect(first, hasLength(2));
    await tester.pumpWidget(frame(1));
    await tester.pumpAndSettle();
    final second = await visible();
    expect(second, hasLength(2));
    expect(second.difference(first), isNotEmpty);
  });
}
