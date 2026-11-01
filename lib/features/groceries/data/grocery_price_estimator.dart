import 'package:miga/features/groceries/data/supermarket_price_source.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';
import 'package:miga/features/groceries/domain/grocery_product.dart';

class GroceryPriceEstimator {
  GroceryPriceEstimator({
    Future<List<StoreSearchResult>> Function(String)? search,
  }) : _search = search ?? SupermarketPriceSource(resultLimit: 48).search;

  final Future<List<StoreSearchResult>> Function(String) _search;
  final _cache = <String, SupermarketOffer>{};
  final _pending = <String, Future<SupermarketOffer?>>{};

  Future<SupermarketOffer?> estimate(
    String name, {
    RecipeIngredient? ingredient,
  }) async {
    final text = name.trim().toLowerCase();
    ingredient ??= GroceryProduct.ingredient(name);
    final key = '${ingredient?.name ?? ''}:$text';
    final cached = _cache[key];
    if (cached != null && !cached.isStale) return cached;
    if (_pending[key] case final request?) return request;
    final request = _lookup(name, ingredient);
    _pending[key] = request;
    try {
      final offer = await request;
      if (offer != null) _cache[key] = offer;
      return offer;
    } finally {
      _pending.remove(key);
    }
  }

  Future<SupermarketOffer?> _lookup(
    String name,
    RecipeIngredient? ingredient,
  ) async {
    try {
      final results = <StoreSearchResult>[];
      for (final term
          in ingredient == null
              ? [name]
              : RecipeCostEstimator.queriesFor(ingredient)) {
        results.addAll(await _search(term));
        if (results
            .expand((r) => r.offers)
            .any(
              (o) =>
                  o.currency == 'DOP' &&
                  o.priceCents > 0 &&
                  !o.isStale &&
                  (ingredient == null ||
                      RecipeCostEstimator.matchesOffer(ingredient, o)),
            )) {
          break;
        }
      }
      final offers = results
          .expand((result) => result.offers)
          .where(
            (offer) =>
                offer.currency == 'DOP' &&
                offer.priceCents > 0 &&
                !offer.isStale &&
                (ingredient == null ||
                    RecipeCostEstimator.matchesOffer(ingredient, offer)),
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
