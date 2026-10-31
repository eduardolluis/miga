import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';
import 'package:miga/features/groceries/presentation/sheets/grocery_list_sheet.dart';
import 'package:miga/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'Automatically prices missing items and preserves user prices when saved',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      List<GroceryItem>? saved;
      final names = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Open'),
                onPressed: () async {
                  saved = await showGroceryList(
                    context,
                    [
                      const GroceryItem('Rice'),
                      const GroceryItem('Milk', unitPriceCents: 9000),
                    ],
                    estimate: (name) async {
                      names.add(name);
                      return SupermarketOffer(
                        store: Supermarket.jumbo,
                        product: 'Rice 5 lb',
                        sku: '1',
                        presentation: '5 lb',
                        priceCents: 20000,
                        sourceUrl: 'https://jumbo.com.do/rice',
                        observedAt: DateTime.now(),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('≈ RD\$200.00'), findsOneWidget);
      expect(names, ['Rice']);
      await tester.enterText(find.byType(TextField), 'Eggs');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Add item'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
      expect(find.text('Product added successfully'), findsOneWidget);
      expect(find.text('Grocery list'), findsOneWidget);
      expect(names, ['Rice', 'Eggs']);
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(saved!.first.isEstimated, isTrue);
      expect(saved![1].unitPriceCents, 9000);
      expect(saved![1].isEstimated, isFalse);
    },
  );
}
