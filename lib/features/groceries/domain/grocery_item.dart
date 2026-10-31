import 'package:miga/features/groceries/domain/grocery_price_reference.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';

class GroceryItem {
  const GroceryItem(
    this.name, {
    this.checked = false,
    this.unitPriceCents,
    this.quantity = 1,
    this.currency = 'DOP',
    this.reference,
    this.offer,
  });

  final String name;
  final bool checked;
  final int? unitPriceCents;
  final int quantity;
  final String currency;
  final GroceryPriceReference? reference;
  final SupermarketOffer? offer;
  int? get totalCents => unitPriceCents == null || (offer?.isStale ?? false)
      ? null
      : unitPriceCents! * quantity;

  GroceryItem withChecked(bool value) => GroceryItem(
    name,
    checked: value,
    unitPriceCents: unitPriceCents,
    quantity: quantity,
    currency: currency,
    reference: reference,
    offer: offer,
  );

  GroceryItem withOffer(SupermarketOffer value) => GroceryItem(
    name,
    checked: checked,
    quantity: quantity,
    currency: value.currency,
    unitPriceCents: value.priceCents,
    offer: value,
  );

  String formatCents(int cents) =>
      '${currency == 'DOP' ? 'RD\$' : 'US\$'}${(cents / 100).toStringAsFixed(2)}';

  Map<String, Object> toJson() => {
    'name': name,
    'checked': checked,
    'quantity': quantity,
    'currency': currency,
    'unitPriceCents': ?unitPriceCents,
    if (reference != null) 'reference': reference!.toJson(),
    if (offer != null) 'offer': offer!.toJson(),
  };

  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem(
    json['name'] as String,
    checked: json['checked'] as bool,
    unitPriceCents: json['unitPriceCents'] as int?,
    quantity: json['quantity'] as int? ?? 1,
    currency: json['currency'] as String? ?? 'DOP',
    reference: json['reference'] == null
        ? null
        : GroceryPriceReference.fromJson(
            json['reference'] as Map<String, dynamic>,
          ),
    offer: json['offer'] == null
        ? null
        : SupermarketOffer.fromJson(json['offer'] as Map<String, dynamic>),
  );
}

class GroceryTotals {
  GroceryTotals(List<GroceryItem> items, String currency) {
    for (final item in items) {
      if (item.currency != currency || item.totalCents == null) {
        missing++;
      } else {
        subtotalCents += item.totalCents!;
        priced++;
      }
    }
  }
  int subtotalCents = 0;
  int missing = 0;
  int priced = 0;
}
