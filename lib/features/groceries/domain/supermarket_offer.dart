enum Supermarket {
  nacional('Nacional', 'Supermercados Nacional'),
  sirena('Sirena', 'Sirena supermercado'),
  jumbo('Jumbo', 'Jumbo supermercado');

  const Supermarket(this.label, this.mapsQuery);
  final String label;
  final String mapsQuery;
}

class SupermarketOffer {
  const SupermarketOffer({
    required this.store,
    required this.product,
    required this.sku,
    required this.presentation,
    required this.priceCents,
    required this.sourceUrl,
    required this.observedAt,
    this.currency = 'DOP',
    this.ean,
  });
  final Supermarket store;
  final String product;
  final String sku;
  final String presentation;
  final int priceCents;
  final String sourceUrl;
  final DateTime observedAt;
  final String currency;
  final String? ean;
  bool get isStale => isStaleAt(DateTime.now());
  bool isStaleAt(DateTime now) {
    final age = now.toUtc().difference(observedAt.toUtc());
    return age.isNegative || age > const Duration(hours: 24);
  }

  Map<String, Object> toJson() => {
    'store': store.name,
    'product': product,
    'sku': sku,
    'presentation': presentation,
    'priceCents': priceCents,
    'sourceUrl': sourceUrl,
    'observedAt': observedAt.toUtc().toIso8601String(),
    'currency': currency,
    'ean': ?ean,
  };

  factory SupermarketOffer.fromJson(Map<String, dynamic> json) =>
      SupermarketOffer(
        store: Supermarket.values.byName(json['store'] as String),
        product: json['product'] as String,
        sku: json['sku'] as String,
        presentation: json['presentation'] as String,
        priceCents: json['priceCents'] as int,
        sourceUrl: json['sourceUrl'] as String,
        observedAt: DateTime.parse(json['observedAt'] as String),
        currency: json['currency'] as String,
        ean: json['ean'] as String?,
      );
}

class StoreSearchResult {
  const StoreSearchResult(
    this.store, {
    this.offers = const [],
    this.unavailable = false,
  });
  final Supermarket store;
  final List<SupermarketOffer> offers;
  final bool unavailable;
}
