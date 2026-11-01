import 'package:miga/core/region/supported_regions.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
import 'package:miga/features/groceries/domain/grocery_price_reference.dart';
import 'package:miga/features/groceries/domain/grocery_product.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';

import 'dart:math' as math;

class GroceryItem {
  const GroceryItem(
    this.name, {
    this.checked = false,
    this.unitPriceCents,
    this.quantity = 1,
    this.currency = 'DOP',
    this.reference,
    this.offer,
    this.isEstimated = false,
    this.ingredientId,
    this.requiredAmount,
    this.requiredUnit,
    this.manualQuantity = false,
    this.planGenerated = false,
  });

  final String name;
  final bool checked;
  final int? unitPriceCents;
  final int quantity;
  final String currency;
  final GroceryPriceReference? reference;
  final SupermarketOffer? offer;
  final bool isEstimated;
  final String? ingredientId;
  final double? requiredAmount;
  final CostUnit? requiredUnit;
  final bool manualQuantity;
  final bool planGenerated;
  bool get fromPlan => planGenerated;

  RecipeIngredient? get ingredientForPricing {
    return RecipeIngredient.values
            .where((v) => v.name == ingredientId)
            .firstOrNull ??
        GroceryProduct.ingredient(name);
  }

  GroceryItem normalizedForPricing() {
    final ingredient = ingredientForPricing;
    if (ingredient == null) return this;
    final count = RegExp(r'^(\d+(?:[.,]\d+)?)\s+').firstMatch(name.trim());
    final pieces = ingredient == RecipeIngredient.eggs && count != null
        ? double.tryParse(count[1]!.replaceAll(',', '.'))
        : null;
    final normalized = GroceryItem(
      name,
      checked: checked,
      quantity: quantity,
      currency: currency,
      unitPriceCents: unitPriceCents,
      reference: reference,
      offer: offer,
      isEstimated: isEstimated,
      ingredientId: ingredient.name,
      requiredAmount: requiredAmount ?? pieces,
      requiredUnit: requiredUnit ?? (pieces != null ? CostUnit.pieces : null),
      manualQuantity: manualQuantity,
      planGenerated: planGenerated,
    );
    return offer != null && !manualQuantity
        ? normalized.withOffer(offer!, estimated: isEstimated)
        : normalized;
  }

  bool get hasInvalidEstimate =>
      isEstimated &&
      offer != null &&
      ingredientForPricing != null &&
      !RecipeCostEstimator.matchesOffer(ingredientForPricing!, offer!);

  GroceryItem withoutPrice() => GroceryItem(
    name,
    checked: checked,
    quantity: quantity,
    currency: currency,
    ingredientId: ingredientId,
    requiredAmount: requiredAmount,
    requiredUnit: requiredUnit,
    manualQuantity: manualQuantity,
    planGenerated: planGenerated,
  );

  GroceryItem copyWith({
    bool? checked,
    int? quantity,
    int? unitPriceCents,
    bool? manualQuantity,
    double? requiredAmount,
    CostUnit? requiredUnit,
  }) => GroceryItem(
    name,
    checked: checked ?? this.checked,
    quantity: quantity ?? this.quantity,
    unitPriceCents: unitPriceCents ?? this.unitPriceCents,
    currency: currency,
    reference: reference,
    offer: offer,
    isEstimated: isEstimated,
    ingredientId: ingredientId,
    requiredAmount: requiredAmount ?? this.requiredAmount,
    requiredUnit: requiredUnit ?? this.requiredUnit,
    manualQuantity: manualQuantity ?? this.manualQuantity,
    planGenerated: planGenerated,
  );
  int? get totalCents =>
      unitPriceCents == null ||
          hasInvalidEstimate ||
          unitPriceCents! < 0 ||
          quantity <= 0 ||
          (offer?.isStale ?? false) ||
          (requiredAmount != null &&
              !manualQuantity &&
              offer != null &&
              RecipeCostEstimator.packageForOffer(offer!)?.$2 != requiredUnit)
      ? null
      : unitPriceCents! * quantity;

  GroceryItem withChecked(bool value) => copyWith(checked: value);

  GroceryItem withQuantity(int value) {
    if (value < 1 || value > 9999) throw ArgumentError.value(value, 'quantity');
    return copyWith(quantity: value, manualQuantity: true);
  }

  GroceryItem withOffer(SupermarketOffer value, {bool estimated = false}) =>
      GroceryItem(
        name,
        checked: checked,
        quantity: _packagesFor(value),
        currency: value.currency,
        unitPriceCents: value.priceCents,
        offer: value,
        isEstimated: estimated,
        ingredientId: ingredientId,
        requiredAmount: requiredAmount,
        requiredUnit: requiredUnit,
        manualQuantity: manualQuantity,
        planGenerated: planGenerated,
      );

  int _packagesFor(SupermarketOffer value) {
    if (requiredAmount == null || manualQuantity) return quantity;
    final pack = RecipeCostEstimator.packageForOffer(value);
    if (pack == null || pack.$2 != requiredUnit) return quantity;
    return math.max(1, (requiredAmount! / pack.$1).ceil());
  }

  String formatCents(int cents) =>
      SupportedRegions.format(currency, cents / 100);

  Map<String, Object> toJson() => {
    'name': name,
    'checked': checked,
    'quantity': quantity,
    'isEstimated': isEstimated,
    'currency': currency,
    'unitPriceCents': ?unitPriceCents,
    if (reference != null) 'reference': reference!.toJson(),
    if (offer != null) 'offer': offer!.toJson(),
    'ingredientId': ?ingredientId,
    'requiredAmount': ?requiredAmount,
    if (requiredUnit != null) 'requiredUnit': requiredUnit!.name,
    'manualQuantity': manualQuantity,
    'planGenerated': planGenerated,
  };

  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem(
    json['name'] as String,
    isEstimated: json['isEstimated'] as bool? ?? false,
    checked: json['checked'] as bool,
    unitPriceCents: json['unitPriceCents'] as int?,
    quantity: json['quantity'] as int? ?? 1,
    currency: json['currency'] as String? ?? 'DOP',
    ingredientId: json['ingredientId'] as String?,
    requiredAmount: (json['requiredAmount'] as num?)?.toDouble(),
    requiredUnit: CostUnit.values
        .where((u) => u.name == json['requiredUnit'])
        .firstOrNull,
    manualQuantity: json['manualQuantity'] == true,
    planGenerated: json['planGenerated'] == true,
    reference: json['reference'] == null
        ? null
        : GroceryPriceReference.fromJson(
            json['reference'] as Map<String, dynamic>,
          ),
    offer: json['offer'] == null
        ? null
        : SupermarketOffer.fromJson(json['offer'] as Map<String, dynamic>),
  ).normalizedForPricing();
}

class GroceryTotals {
  GroceryTotals(
    List<GroceryItem> items,
    String currency, {
    bool includeChecked = true,
  }) {
    for (final item in items) {
      if (!includeChecked && item.checked) continue;
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
