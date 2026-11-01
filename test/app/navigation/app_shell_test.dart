import '../../support/recipe_catalog.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miga/app/navigation/app_shell.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/home/data/local_home_details_store.dart';
import 'package:miga/features/home/domain/home_details.dart';
import 'package:miga/features/pro/presentation/pro_page.dart';
import 'package:miga/features/recipes/presentation/recipes_page.dart';
import 'package:miga/features/groceries/presentation/groceries_tab_page.dart';
import 'package:miga/l10n/app_localizations.dart';

Widget _frame({String language = 'es'}) => MaterialApp(
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: AppShell(
    recipeRepository: RecipeCatalog.repository(),
    today: DateTime(2026, 10, 30, 13),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Home shows the three-slide reference banner, not old budget widgets',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_frame());
      await tester.pumpAndSettle();
      expect(find.text('Miga'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('home-featured-banner')),
        findsOneWidget,
      );
      final view = tester.widget<PageView>(
        find.byKey(const ValueKey('home-featured-banner')),
      );
      expect(view.childrenDelegate.estimatedChildCount, 3);
      expect(find.text('Presupuesto semanal'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('A fourth Surprise use opens Miga Pro', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({'miga_surprise_guest_used': 3});
    await tester.pumpWidget(_frame(language: 'en'));
    await tester.pumpAndSettle();
    final surprise = find.byKey(const ValueKey('home-quick-surprise'));
    await tester.scrollUntilVisible(
      surprise,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(surprise), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(surprise);
    await tester.pumpAndSettle();
    expect(find.byType(ProPage), findsOneWidget);
  });

  testWidgets('Cheaper alternatives are gated by Miga Pro', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_frame(language: 'en'));
    await tester.pumpAndSettle();
    final cheaper = find.byKey(const ValueKey('home-quick-cheaper'));
    await tester.scrollUntilVisible(
      cheaper,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(cheaper), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(cheaper);
    await tester.pumpAndSettle();
    expect(find.byType(ProPage), findsOneWidget);
  });

  testWidgets('Free users are redirected from Plan to Miga Pro', (
    tester,
  ) async {
    await tester.pumpWidget(_frame());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.byType(ProPage), findsOneWidget);
    expect(find.text('Miga Pro'), findsWidgets);
  });

  testWidgets('Recipes remains available to Free users', (tester) async {
    await tester.pumpWidget(_frame());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recetas'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipesPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Groceries renders ingredient artwork and persists a checked item',
    (tester) async {
      await LocalHomeDetailsStore('guest').save(
        const HomeDetails(
          groceries: [GroceryItem('2 eggs', ingredientId: 'eggs')],
        ),
      );
      await tester.pumpWidget(_frame());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compras'));
      await tester.pumpAndSettle();
      expect(find.byType(GroceriesTabPage), findsOneWidget);
      final row = find.byKey(const ValueKey('grocery-item-eggs'));
      expect(row, findsOneWidget);
      await tester.tap(
        find.descendant(
          of: row,
          matching: find.byIcon(Icons.radio_button_unchecked_rounded),
        ),
      );
      await tester.pumpAndSettle();
      final items = (await LocalHomeDetailsStore('guest').load()).groceries;
      expect(items.single.checked, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
