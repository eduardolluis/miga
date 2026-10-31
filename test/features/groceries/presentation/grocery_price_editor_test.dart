import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/groceries/domain/grocery_price_reference.dart';
import 'package:miga/features/groceries/presentation/sheets/grocery_price_editor.dart';
import 'package:miga/features/groceries/presentation/sheets/grocery_reference_picker.dart';
import 'package:miga/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'Official reference picker displays period and package at large text sizes',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: GroceryReferencePicker(
              load: () async => const [
                GroceryPriceReference(
                  product: 'Arroz',
                  presentation: 'Funda 10 Lb.',
                  priceCents: 33374,
                  month: 'Septiembre',
                  year: 2026,
                  segment: 'supermercados grandes',
                  sourceUrl: 'https://proconsumidor.gob.do/prices.csv',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('Funda 10 Lb.'),
        150,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Funda 10 Lb.'), findsOneWidget);
      expect(find.textContaining('Septiembre 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Price editor validates decimals and returns a quantity-based estimate',
    (tester) async {
      GroceryItem? saved;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  saved = await showDialog<GroceryItem>(
                    context: context,
                    builder: (_) =>
                        const GroceryPriceEditor(item: GroceryItem('Eggs')),
                  );
                },
                child: const Text('Edit price'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Edit price'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('grocery-unit-price')),
        '-2',
      );
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('grocery-unit-price')),
        '120,50',
      );
      await tester.enterText(
        find.byKey(const ValueKey('grocery-quantity')),
        '2',
      );
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(saved!.unitPriceCents, 12050);
      expect(saved!.totalCents, 24100);
      expect(saved!.reference, isNull);
    },
  );
}
