import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';

abstract interface class RecipePriceStore {
  Future<Map<String, List<SupermarketOffer>>> load();
  Future<void> save(Map<String, List<SupermarketOffer>> offers);
}

class LocalRecipePriceStore implements RecipePriceStore {
  static const _key = 'miga.recipe-prices.do.dop.v1';
  String? _lastEncoded;

  @override
  Future<Map<String, List<SupermarketOffer>>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return {};
    _lastEncoded = raw;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final result = <String, List<SupermarketOffer>>{};
    for (final entry in decoded.entries) {
      final offers = <SupermarketOffer>[];
      for (final value in entry.value as List) {
        try {
          offers.add(
            SupermarketOffer.fromJson((value as Map).cast<String, dynamic>()),
          );
        } catch (_) {
          // A malformed quote must not discard the remaining valid entries.
        }
      }
      result[entry.key] = offers;
    }
    return result;
  }

  @override
  Future<void> save(Map<String, List<SupermarketOffer>> offers) async {
    final encoded = jsonEncode({
      for (final entry in offers.entries)
        entry.key: entry.value.map((offer) => offer.toJson()).toList(),
    });
    if (encoded == _lastEncoded) return;
    final preferences = await SharedPreferences.getInstance();
    if (await preferences.setString(_key, encoded)) _lastEncoded = encoded;
  }
}
