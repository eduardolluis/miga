import 'package:miga/features/groceries/data/supermarket_price_source.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';

class GroceryPriceEstimator {
  GroceryPriceEstimator({
    Future<List<StoreSearchResult>> Function(String)? search,
  }) : _search = search ?? SupermarketPriceSource().search;

  final Future<List<StoreSearchResult>> Function(String) _search;
  final _cache = <String, SupermarketOffer>{};
  final _pending = <String, Future<SupermarketOffer?>>{};

  Future<SupermarketOffer?> estimate(String name) async {
    final key = name.trim().toLowerCase();
    final cached = _cache[key];
    if (cached != null && !cached.isStale) return cached;
    if (_pending[key] case final request?) return request;
    final request = _lookup(name);
    _pending[key] = request;
    try {
      final offer = await request;
      if (offer != null) _cache[key] = offer;
      return offer;
    } finally {
      _pending.remove(key);
    }
  }

  Future<SupermarketOffer?> _lookup(String name) async {
    try {
      final results = await _search(name);
      final offers = results
          .expand((result) => result.offers)
          .where(
            (offer) =>
                offer.currency == 'DOP' &&
                offer.priceCents > 0 &&
                !offer.isStale,
          )
          .toList();
      if (offers.isEmpty) return null;
      // Estimate one purchasable package; never imply equivalent brands or sizes.
      final regular = offers
          .where((offer) => offer.store != Supermarket.pricesmart)
          .toList();
      final candidates = regular.isEmpty ? offers : regular;
      candidates.sort((a, b) => a.priceCents.compareTo(b.priceCents));
      return candidates.first;
    } catch (_) {
      return null;
    }
  }
}
