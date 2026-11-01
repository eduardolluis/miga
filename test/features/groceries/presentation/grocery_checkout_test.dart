import '../../../support/recipe_catalog.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miga/app/navigation/app_shell.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/home/application/home_controller.dart';
import 'package:miga/features/home/data/local_home_details_store.dart';
import 'package:miga/features/home/domain/home_details.dart';
import 'package:miga/features/home/domain/home_details_store.dart';
import 'package:miga/features/meal_plan/data/local_meal_plan_store.dart';
import 'package:miga/l10n/app_localizations.dart';

class MemoryStore implements HomeDetailsStore {
  HomeDetails data = const HomeDetails();
  bool fail = false;
  @override
  Future<HomeDetails> load() async => data;
  @override
  Future<void> save(HomeDetails details) async {
    if (fail) throw StateError('offline');
    data = details;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('Checkout saves items and actual paid amount separately from a partial estimate', () async {
    final controller = HomeController(
      recipeRepository: RecipeCatalog.repository(),
      today: DateTime(2026, 10, 31),
      planStore: LocalMealPlanStore('checkout'),
      detailsStore: LocalHomeDetailsStore('checkout'),
    );
    addTearDown(controller.dispose);
    await controller.load();
    final items = [
      const GroceryItem('Rice', checked: true, unitPriceCents: 10000),
      const GroceryItem('Unknown', checked: true),
    ];
    await controller.saveGroceries(items);
    expect(
      await controller.completeGroceries(items, paidTotalCents: 15000),
      isTrue,
    );
    await controller.load();
    expect(controller.details.groceries, isEmpty);
    expect(controller.details.syncGroceries, isFalse);
    final purchase = controller.details.purchases.single;
    expect(purchase.items.length, 2);
    expect(purchase.paidTotalCents, 15000);
    expect(purchase.estimatedTotalCents, 10000);
    expect(purchase.missingPrices, 1);
    expect(purchase.currency, 'DOP');
    expect(
      await controller.completeGroceries(controller.details.groceries),
      isFalse,
    );
    expect(controller.details.purchases.length, 1);
  });
  test('Failed checkout preserves the cart; undo restores cart and removes the record', () async {
    final store = MemoryStore();
    final controller = HomeController(
      recipeRepository: RecipeCatalog.repository(),
      today: DateTime(2026, 10, 31),
      planStore: LocalMealPlanStore('checkout'),
      detailsStore: store,
    );
    addTearDown(controller.dispose);
    await controller.load();
    const items = [GroceryItem('Rice', checked: true, unitPriceCents: 10000)];
    await controller.saveGroceries(items);
    expect(
      await controller.completeGroceries([const GroceryItem('Rice')]),
      isFalse,
    );
    store.fail = true;
    expect(await controller.completeGroceries(items), isFalse);
    expect(controller.details.groceries.length, 1);
    expect(controller.details.purchases, isEmpty);
    store.fail = false;
    expect(await controller.completeGroceries(items), isTrue);
    expect(controller.details.purchases.single.paidTotalCents, isNull);
    expect(await controller.undo(), isTrue);
    expect(controller.details.groceries.length, 1);
    expect(controller.details.purchases, isEmpty);
  });
  testWidgets(
    'Completing the checked cart saves the receipt total and clears the list',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = LocalHomeDetailsStore('guest');
      await store.save(
        const HomeDetails(
          groceries: [GroceryItem('Eggs', unitPriceCents: 6500)],
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppShell(
            recipeRepository: RecipeCatalog.repository(),
            today: DateTime(2026, 10, 31),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('grocery-complete')), findsNothing);
      await tester.tap(find.byIcon(Icons.radio_button_unchecked_rounded));
      await tester.pumpAndSettle();
      final complete = find.byKey(const ValueKey('grocery-complete'));
      await tester.scrollUntilVisible(complete, 120);
      await tester.pumpAndSettle();
      await tester.tap(complete);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('checkout-paid-total')),
        '60.50',
      );
      await tester.tap(find.byKey(const ValueKey('checkout-confirm')));
      await tester.pumpAndSettle();
      final saved = await store.load();
      expect(saved.groceries, isEmpty);
      expect(saved.purchases.single.paidTotalCents, 6050);
      expect(find.byKey(const ValueKey('grocery-complete')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
