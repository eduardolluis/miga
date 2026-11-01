import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/recipe_catalog.dart';

import 'package:miga/features/recipes/presentation/recipes_page.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_card.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_pagination.dart';
import 'package:miga/l10n/app_localizations.dart';

Widget catalog() => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: RecipesPage(
      repository: RecipeCatalog.repository(),
      onOpenRecipe: (_) {},
    ),
  ),
);

void main() {
  testWidgets(
    'All recipes can be reached once across bounded pages with working boundaries',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 3500));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(catalog());
      await tester.pumpAndSettle();
      expect(find.byType(RecipePagination), findsOneWidget);
      final cards = find.byType(RecipeCard);
      final positions = [
        for (var i = 0; i < 6; i++) tester.getTopLeft(cards.at(i)),
      ];
      for (var row = 0; row < 3; row++) {
        expect(positions[row * 2].dy, positions[row * 2 + 1].dy);
        expect(positions[row * 2].dx, lessThan(positions[row * 2 + 1].dx));
      }
      expect(
        tester
            .getSize(find.byKey(const ValueKey('recipes-next-bottom')))
            .height,
        tester
            .getSize(find.byKey(const ValueKey('recipes-previous-bottom')))
            .height,
      );
      final ids = <String>[];
      final totalPages = (RecipeCatalog.all.length / 6).ceil();
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('recipes-previous-bottom')),
            )
            .onPressed,
        isNull,
      );
      for (var page = 0; page < totalPages; page++) {
        final visible = tester
            .widgetList<RecipeCard>(find.byType(RecipeCard))
            .map((c) => c.recipe.id)
            .toList();
        expect(
          visible.length,
          page == totalPages - 1 ? RecipeCatalog.all.length - page * 6 : 6,
        );
        expect(find.text('Page ${page + 1} of $totalPages'), findsOneWidget);
        ids.addAll(visible);
        if (page < totalPages - 1) {
          await tester.tap(find.byKey(const ValueKey('recipes-next-bottom')));
          await tester.pumpAndSettle();
        }
      }
      expect(ids.toSet().length, RecipeCatalog.all.length);
      expect(ids.length, RecipeCatalog.all.length);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('recipes-next-bottom')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('recipes-previous-bottom')));
      await tester.pumpAndSettle();
      expect(
        find.text('Page ${totalPages - 1} of $totalPages'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Search, meal filters and sorting restart pagination', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 3500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(catalog());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipes-next-bottom')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('recipe-search')),
      'apple cinnamon',
    );
    await tester.pumpAndSettle();
    expect(find.byType(RecipeCard), findsOneWidget);
    expect(find.byType(RecipePagination), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('recipe-search')), '');
    await tester.pumpAndSettle();
    expect(find.text('Page 1 of 9'), findsOneWidget);
    await tester.tap(find.text('Breakfast'));
    await tester.pumpAndSettle();
    expect(find.text('Page 1 of 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('recipes-next-bottom')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipes-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quickest'));
    await tester.pumpAndSettle();
    expect(find.text('Page 1 of 3'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('recipe-search')),
      'nothing-matches-this',
    );
    await tester.pumpAndSettle();
    expect(find.byType(RecipePagination), findsNothing);
    expect(find.byType(RecipeCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Next at the bottom returns to the start of the new page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(catalog());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('recipes-next-bottom')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final view = tester.widget<CustomScrollView>(find.byType(CustomScrollView));
    expect(view.controller!.offset, greaterThan(0));
    await tester.tap(find.byKey(const ValueKey('recipes-next-bottom')));
    await tester.pumpAndSettle();
    expect(view.controller!.offset, 0);
    expect(
      find.byKey(const ValueKey('recipe-search')).hitTestable(),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Page 2 of 9'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Page 2 of 9').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['en', 'es']) {
    testWidgets(
      'Pagination controls fit narrow screens with large text in $language',
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
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    RecipePagination(
                      page: 0,
                      pages: 5,
                      onPrevious: null,
                      onNext: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
