import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/home/presentation/widgets/budget_recipe_suggestions.dart';
import 'package:miga/features/home/presentation/widgets/recipe_cost_sheet.dart';

import '../../../support/recipe_catalog.dart';

import 'package:miga/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'Home price badges update from shared costs without opening a recipe',
    (tester) async {
      final recipe = RecipeCatalog.all.first;
      var ready = false;
      var opened = false;
      RecipeCost costFor(_) => RecipeCost(recipe, [
        for (final amount in RecipeAmounts.forRecipe(recipe))
          IngredientCost(amount, cents: ready ? 10000 : null),
      ]);
      Widget app() => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BudgetRecipeSuggestions(
              now: DateTime(2026, 10, 31),
              recipes: [recipe],
              costFor: costFor,
              pricing: !ready,
              onRecipe: (_) => opened = true,
            ),
          ),
        ),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Estimating…'), findsOneWidget);
      ready = true;
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('≈ RD\$500'), findsOneWidget);
      expect(find.text('Estimating…'), findsNothing);
      expect(opened, isFalse);
    },
  );

  testWidgets('Budget Home has at most two cards and See all is interactive', (
    tester,
  ) async {
    final recipes = RecipeCatalog.all.take(5).toList();
    final costs = [
      for (final recipe in recipes)
        RecipeCost(recipe, [
          for (final ingredient in RecipeAmounts.forRecipe(recipe))
            IngredientCost(ingredient, cents: 100),
        ]),
    ];
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
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
              now: DateTime(2026, 11, 1, 13),
              recipes: recipes,
              estimate: (_) async => costs,
              onRecipe: (_) {},
              onSeeAll: () => opened = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final visible = recipes
        .where(
          (recipe) => find
              .byKey(ValueKey('budget-recipe-${recipe.id}'))
              .evaluate()
              .isNotEmpty,
        )
        .length;
    expect(visible, 2);
    await tester.tap(find.byKey(const ValueKey('budget-see-all')));
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('No configured budget still shows two recipe ideas', (
    tester,
  ) async {
    final recipes = RecipeCatalog.all.take(3).toList();
    final unpriced = [
      for (final recipe in recipes)
        RecipeCost(recipe, [
          for (final amount in RecipeAmounts.forRecipe(recipe))
            IngredientCost(amount),
        ]),
    ];
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BudgetRecipeSuggestions(
              now: DateTime(2026, 10, 31, 20),
              recipes: recipes,
              estimate: (_) async => unpriced,
              onRecipe: (_) {},
              onSeeAll: () => opened = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('budget-recipes-preview')),
      findsOneWidget,
    );
    expect(find.textContaining('Set a budget in Profile'), findsOneWidget);
    for (final recipe in recipes.take(2)) {
      expect(
        find.byKey(ValueKey('budget-recipe-${recipe.id}')),
        findsOneWidget,
      );
    }
    expect(find.byKey(const ValueKey('budget-see-all')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('budget-see-all')));
    expect(opened, isTrue);
  });

  testWidgets('Pricing failure falls back to photos with unknown costs', (
    tester,
  ) async {
    final recipes = RecipeCatalog.all.take(2).toList();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BudgetRecipeSuggestions(
              now: DateTime(2026, 10, 31, 20),
              recipes: recipes,
              estimate: (_) async => throw Exception('offline'),
              onRecipe: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final recipe in recipes) {
      expect(
        find.byKey(ValueKey('budget-recipe-${recipe.id}')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  for (final language in ['en', 'es']) {
    testWidgets(
      'Ingredient breakdown fits narrow screens with large text in $language',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final recipe = RecipeCatalog.all.first;
        final cost = RecipeCost(recipe, [
          for (final amount in recipe.amounts)
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
        for (final amount in recipe.amounts)
          IngredientCost(amount, cents: 1000),
      ]);
      final other = RecipeCatalog.all[1];
      final partial = RecipeCost(other, [
        for (final amount in other.amounts) IngredientCost(amount),
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
      expect(find.text('Meals for your budget'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('budget-recipe-banana-oats')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('budget-recipe-avocado-toast')),
        findsOneWidget,
      );
      expect(find.textContaining('prices'), findsWidgets);
      expect(find.textContaining('per serving'), findsNothing);
      await tester.pumpWidget(app(10));
      await tester.pumpAndSettle();
      // The affordable filter has no confirmed matches, but Home still shows
      // recipe IDEAS with a warning rather than an empty preview.
      expect(
        find.byKey(const ValueKey('budget-recipe-banana-oats')),
        findsOneWidget,
      );
      expect(find.textContaining('No fully priced meal fits'), findsOneWidget);
      expect(find.byKey(const ValueKey('budget-see-all')), findsOneWidget);
    },
  );
}
