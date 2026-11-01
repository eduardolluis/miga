import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/groceries/presentation/sheets/grocery_list_sheet.dart';
import 'package:miga/features/home/application/home_controller.dart';
import 'package:miga/features/home/data/local_home_details_store.dart';
import 'package:miga/features/meal_plan/data/local_meal_plan_store.dart';

import '../../../support/recipe_catalog.dart';

import 'package:miga/l10n/app_localizations.dart';

void main() {
  for (final hasPlan in [false, true]) {
    testWidgets(
      'Generating preserves pending grocery edits with plan=$hasPlan',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final controller = HomeController(
          recipeRepository: RecipeCatalog.repository(),
          today: DateTime(2026, 10, 30),
          planStore: LocalMealPlanStore('guest'),
          detailsStore: LocalHomeDetailsStore('guest'),
        );
        addTearDown(controller.dispose);
        await controller.load();
        await controller.saveGroceries([
          const GroceryItem('Bread', unitPriceCents: 9000),
          const GroceryItem('Soap', unitPriceCents: 1000),
        ]);
        if (hasPlan) {
          final recipe = RecipeCatalog.all.first;
          await controller.saveMeal(
            controller.today,
            recipe.slot,
            recipe.en.title,
          );
        }
        await tester.binding.setSurfaceSize(const Size(900, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        List<GroceryItem>? saved;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  child: const Text('Open'),
                  onPressed: () async {
                    saved = await showGroceryList(
                      context,
                      controller.details.groceries,
                      isPro: true,
                      estimate: (_) async => null,
                      onGenerateFromPlan: (items) =>
                          controller.generateGroceriesFromPlannedMeals(
                            existingItems: items,
                            languageCode: 'en',
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
        await tester.tap(find.byIcon(Icons.add_circle_outline).first);
        await tester.tap(find.byKey(const ValueKey('grocery-check-0')));
        await tester.tap(find.byTooltip('Remove item').last);
        await tester.enterText(find.byType(TextField), 'Coffee');
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Add item'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Generate from weekly plan'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save changes'));
        await tester.pumpAndSettle();

        final bread = saved!.singleWhere((item) => item.name == 'Bread');
        expect(bread.quantity, 2);
        expect(bread.checked, isTrue);
        expect(bread.unitPriceCents, 9000);
        expect(saved!.map((item) => item.name), contains('Coffee'));
        expect(saved!.map((item) => item.name), isNot(contains('Soap')));
        expect(saved!.map((item) => item.name).contains('Oats'), hasPlan);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
