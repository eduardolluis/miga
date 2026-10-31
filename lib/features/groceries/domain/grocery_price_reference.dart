class GroceryPriceReference {
  const GroceryPriceReference({
    required this.product,
    required this.presentation,
    required this.priceCents,
    required this.month,
    required this.year,
    required this.segment,
    required this.sourceUrl,
    this.countryCode = 'DO',
    this.currency = 'DOP',
  });

  final String product;
  final String presentation;
  final int priceCents;
  final String month;
  final int year;
  final String segment;
  final String sourceUrl;
  final String countryCode;
  final String currency;

  Map<String, Object> toJson() => {
    'product': product,
    'presentation': presentation,
    'priceCents': priceCents,
    'month': month,
    'year': year,
    'segment': segment,
    'sourceUrl': sourceUrl,
    'countryCode': countryCode,
    'currency': currency,
  };

  factory GroceryPriceReference.fromJson(Map<String, dynamic> json) =>
      GroceryPriceReference(
        product: json['product'] as String,
        presentation: json['presentation'] as String,
        priceCents: json['priceCents'] as int,
        month: json['month'] as String,
        year: json['year'] as int,
        segment: json['segment'] as String,
        sourceUrl: json['sourceUrl'] as String,
        countryCode: json['countryCode'] as String,
        currency: json['currency'] as String,
      );
}
