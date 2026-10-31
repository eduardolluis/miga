import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';
import 'package:miga/features/groceries/presentation/sheets/supermarket_comparison_page.dart';
import 'package:miga/features/stores/data/nearby_stores.dart';
import 'package:miga/l10n/app_localizations.dart';

void main() {
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
