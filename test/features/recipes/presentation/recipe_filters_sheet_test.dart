import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
import 'package:miga/features/recipes/presentation/sheets/recipe_filters_sheet.dart';
import 'package:miga/l10n/app_localizations.dart';

void main() {
  for (final language in ['en', 'es']) {
    testWidgets(
      'Filter sheet fits narrow screens and large text in $language',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
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
            home: const Scaffold(
              body: RecipeFiltersSheet(
                initial: RecipeFilters(),
                hasBudget: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('filters-apply')).hitTestable(),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('filter-ingredient-search')),
          220,
        );
        await tester.enterText(
          find.byKey(const ValueKey('filter-ingredient-search')),
          language == 'en' ? 'avocado' : 'aguacate',
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('ingredient-avocado')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('ingredient-banana')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Filter edits apply together, can reset, and cancel leaves no result',
    (tester) async {
      RecipeFilters? result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Open'),
                onPressed: () async {
                  result = await showModalBottomSheet<RecipeFilters>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => const RecipeFiltersSheet(
                      initial: RecipeFilters(
                        ingredients: {RecipeIngredient.eggs},
                      ),
                      hasBudget: true,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter-quick')));
      await tester.tap(find.byKey(const ValueKey('filters-apply')));
      await tester.pumpAndSettle();
      expect(result!.quick, isTrue);
      expect(result!.ingredients, {RecipeIngredient.eggs});
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filters-reset')));
      await tester.tap(find.byKey(const ValueKey('filters-apply')));
      await tester.pumpAndSettle();
      expect(result!.ingredients, isEmpty);
      expect(result!.quick, isFalse);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filters-close')));
      await tester.pumpAndSettle();
      expect(result, isNull);
    },
  );
}
