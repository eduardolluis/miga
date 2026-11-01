import 'package:miga/features/groceries/domain/grocery_item.dart';

class GroceryPurchase {
  const GroceryPurchase({
    required this.id,
    required this.completedAt,
    required this.items,
    required this.currency,
    required this.estimatedTotalCents,
    required this.missingPrices,
    this.paidTotalCents,
  });
  final String id, currency;
  final DateTime completedAt;
  final List<GroceryItem> items;
  final int estimatedTotalCents, missingPrices;
  final int? paidTotalCents;
  Map<String, Object?> toJson() => {
    'id': id,
    'completedAt': completedAt.toIso8601String(),
    'currency': currency,
    'items': items.map((i) => i.toJson()).toList(),
    'estimatedTotalCents': estimatedTotalCents,
    'missingPrices': missingPrices,
    'paidTotalCents': paidTotalCents,
  };
  factory GroceryPurchase.fromJson(Map<String, dynamic> json) =>
      GroceryPurchase(
        id: json['id'] as String,
        completedAt: DateTime.parse(json['completedAt'] as String),
        currency: json['currency'] as String,
        items: (json['items'] as List)
            .map((i) => GroceryItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        estimatedTotalCents: json['estimatedTotalCents'] as int,
        missingPrices: json['missingPrices'] as int,
        paidTotalCents: json['paidTotalCents'] as int?,
      );
}
