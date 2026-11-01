import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';
import 'package:miga/features/groceries/presentation/sheets/supermarket_comparison_page.dart';
import 'package:miga/features/groceries/presentation/sheets/grocery_list_sheet.dart';
import 'package:miga/features/stores/data/nearby_stores.dart';
import 'package:miga/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'Comparison searches the ingredient across stores, not the previous brand',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
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
      String? searched;
      List<GroceryItem>? chosen;
      final request = Completer<List<StoreSearchResult>>();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Open'),
                onPressed: () async {
                  chosen = await compareGroceryItems(
                    context,
                    [
                      const GroceryItem(
                        '2 eggs',
                        checked: true,
                      ).withOffer(offer),
                    ],
                    search: (query) {
                      searched = query;
                      return request.future;
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(searched, 'Huevos');
      expect(find.byType(CircularProgressIndicator), findsNWidgets(4));
      request.complete([
        StoreSearchResult(Supermarket.sirena, offers: [offer]),
      ]);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('RD\$10.83 per egg'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Use this product and price'),
        80,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use this product and price'));
      await tester.pumpAndSettle();
      expect(chosen!.single.checked, isTrue);
      expect(chosen!.single.requiredAmount, 2);
      expect(chosen!.single.quantity, 1);
      expect(chosen!.single.totalCents, 6500);
    },
  );
  testWidgets('Choose a store price and open the map for that chain', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final offer = SupermarketOffer(
      store: Supermarket.nacional,
      product: 'Arroz Líder 10 Lb',
      sku: 'sku-1',
      presentation: 'Arroz Líder 10 Lb',
      priceCents: 33995,
      sourceUrl: 'https://supermercadosnacional.com/arroz-lider',
      observedAt: DateTime.now(),
    );
    Supermarket? mapStore;
    SupermarketOffer? chosen;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                chosen = await showDialog<SupermarketOffer>(
                  context: context,
                  builder: (_) => SupermarketComparisonPage(
                    query: 'Arroz',
                    search: (_) async => [
                      StoreSearchResult(Supermarket.nacional, offers: [offer]),
                    ],
                    openMaps: (store, _) async {
                      mapStore = store;
                      return true;
                    },
                  ),
                );
              },
              child: const Text('Compare'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Compare'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('store-map-nacional')));
    await tester.pumpAndSettle();
    expect(mapStore, Supermarket.nacional);
    await tester.scrollUntilVisible(
      find.text('Use this product and price'),
      120,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Use this product and price'));
    await tester.pumpAndSettle();
    expect(chosen, offer);
    final item = const GroceryItem(
      'Rice',
      quantity: 2,
      checked: true,
    ).withOffer(chosen!);
    final restored = GroceryItem.fromJson(item.toJson());
    expect(restored.totalCents, 67990);
    expect(restored.offer!.store, Supermarket.nacional);
    expect(restored.offer!.sku, 'sku-1');
    expect(restored.checked, isTrue);
  });

  test(
    'Nearby map searches keep the selected chain and let Maps handle location',
    () {
      final uri = NearbyStores.searchUri(
        'es',
        supermarket: Supermarket.sirena.mapsQuery,
      );
      expect(uri.host, 'www.google.com');
      expect(uri.queryParameters['query'], 'Sirena supermercado cerca de mí');
      expect(uri.queryParameters['api'], '1');
    },
  );
}
