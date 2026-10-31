import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/recipes/data/recipe_catalog.dart';
import 'package:miga/features/recipes/presentation/recipes_page.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_card.dart';
import 'package:miga/l10n/app_localizations.dart';

Widget frame(String language) => MaterialApp(
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: RecipesPage(onOpenRecipe: (_) {})),
);

List<String> shownRecipes(WidgetTester tester) {
  final list = tester.widget<ListView>(
    find.byKey(const PageStorageKey('recipes-catalog')),
  );
  return (list.childrenDelegate as SliverChildListDelegate).children
      .whereType<RecipeCard>()
      .map((card) => card.recipe.id)
      .toList();
}

Future<void> selectIngredient(WidgetTester tester, String id) async {
  final chip = find.byKey(ValueKey('ingredient-$id'));
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['en', 'es']) {
    testWidgets('Ingredient matches update, rank, and clear in $language', (
      tester,
    ) async {
      await tester.pumpWidget(frame(language));
      expect(shownRecipes(tester), hasLength(RecipeCatalog.all.length));
      await selectIngredient(tester, 'eggs');
      expect(shownRecipes(tester), ['avocado-toast', 'sweet-potato-egg']);
      await selectIngredient(tester, 'spinach');
      expect(shownRecipes(tester).first, 'sweet-potato-egg');
      expect(
        find.text(
          language == 'en'
              ? '2 ingredients you have · 4 still needed'
              : '2 ingredientes disponibles · 4 por conseguir',
        ),
        findsOneWidget,
      );
      final clear = find.text(language == 'en' ? 'Clear' : 'Limpiar');
      await tester.ensureVisible(clear);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(shownRecipes(tester), hasLength(RecipeCatalog.all.length));
    });
  }

  testWidgets('Ingredient selection works with search and meal filters', (
    tester,
  ) async {
    await tester.pumpWidget(frame('en'));
    await selectIngredient(tester, 'eggs');
    final dinner = find.widgetWithText(ChoiceChip, 'Dinner');
    await tester.scrollUntilVisible(
      dinner,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(dinner);
    await tester.pumpAndSettle();
    expect(shownRecipes(tester), ['sweet-potato-egg']);
    await tester.scrollUntilVisible(
      find.byType(TextField),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), 'salmon');
    await tester.pumpAndSettle();
    expect(shownRecipes(tester), isEmpty);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(shownRecipes(tester), ['sweet-potato-egg']);
  });
}
