import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';
import 'package:miga/features/groceries/presentation/groceries_tab_page.dart';
import 'package:miga/features/groceries/presentation/sheets/grocery_list_sheet.dart';
import 'package:miga/l10n/app_localizations.dart';

void main() {
  for (final language in ['en', 'es']) {
    testWidgets(
      'Shopping page and editor fit a narrow screen with large text in $language',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final offer = SupermarketOffer(
          store: Supermarket.sirena,
          product: 'Huevos Extra Grandes Blanco 6/1 Endy',
          sku: 'eggs',
          presentation: '1 Und.',
          priceCents: 6500,
          sourceUrl: 'https://nuevo.sirena.do/huevos/p',
          observedAt: DateTime.now(),
        );
        final items = [
          const GroceryItem('2 eggs').normalizedForPricing().withOffer(offer),
        ];
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => GroceriesTabPage(
                  items: items,
                  onEdit: () async {
                    await showGroceryList(
                      context,
                      items,
                      estimate: (_) async => null,
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final edit = find.byIcon(Icons.edit_note_rounded);
        await tester.scrollUntilVisible(edit, 160);
        await tester.pumpAndSettle();
        await tester.tap(edit);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView).last, const Offset(0, -700));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
