import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/groceries/data/supermarket_price_source.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/groceries/domain/grocery_product.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';
import 'package:miga/features/groceries/presentation/widgets/grocery_price_summary.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
import 'package:miga/features/stores/data/nearby_stores.dart';
import 'package:miga/l10n/app_localizations.dart';

class SupermarketComparisonPage extends StatefulWidget {
  const SupermarketComparisonPage({
    super.key,
    required this.query,
    this.ingredient,
    this.search,
    this.openMaps,
  });
  final String query;
  final RecipeIngredient? ingredient;
  final Future<List<StoreSearchResult>> Function(String)? search;
  final Future<bool> Function(Supermarket, String)? openMaps;
  @override
  State<SupermarketComparisonPage> createState() =>
      _SupermarketComparisonPageState();
}

class _SupermarketComparisonPageState extends State<SupermarketComparisonPage> {
  late final _input = TextEditingController(text: widget.query);
  final _source = SupermarketPriceSource(resultLimit: 48);
  final _results = <Supermarket, StoreSearchResult>{};
  final _pending = <Supermarket>{};
  final _busy = <String>{};
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _generation++;
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final text = _input.text.trim();
    setState(() {
      _results.clear();
      _pending.clear();
    });
    if (text.length < 2) return;
    final ingredient = text == widget.query
        ? widget.ingredient ?? GroceryProduct.ingredient(text)
        : GroceryProduct.ingredient(text);
    final terms = ingredient == null
        ? [GroceryProduct.name(text)]
        : RecipeCostEstimator.queriesFor(ingredient);
    List<SupermarketOffer> matches(List<SupermarketOffer> offers) =>
        offers
            .where(
              (o) =>
                  !o.isStale &&
                  o.currency == 'DOP' &&
                  o.priceCents > 0 &&
                  (ingredient == null ||
                      RecipeCostEstimator.matchesOffer(ingredient, o)),
            )
            .toList()
          ..sort((a, b) => a.priceCents.compareTo(b.priceCents));
    setState(() => _pending.addAll(Supermarket.values));
    if (widget.search != null) {
      try {
        final results = await widget.search!(terms.first);
        if (!mounted || generation != _generation) return;
        setState(() {
          for (final r in results) {
            _results[r.store] = StoreSearchResult(
              r.store,
              offers: matches(r.offers),
              unavailable: r.unavailable,
            );
          }
          _pending.clear();
        });
      } catch (_) {
        if (!mounted || generation != _generation) return;
        setState(() {
          for (final store in Supermarket.values) {
            _results[store] = StoreSearchResult(store, unavailable: true);
          }
          _pending.clear();
        });
      }
      return;
    }
    await Future.wait(
      Supermarket.values.map((store) async {
        StoreSearchResult result = StoreSearchResult(store);
        for (final term in terms) {
          final response = await _source.search(term, stores: {store});
          if (!mounted || generation != _generation) return;
          final r = response.firstOrNull ?? StoreSearchResult(store);
          result = StoreSearchResult(
            store,
            offers: matches(r.offers),
            unavailable: r.unavailable,
          );
          if (result.offers.isNotEmpty || result.unavailable) break;
        }
        if (!mounted || generation != _generation) return;
        setState(() {
          _results[store] = result;
          _pending.remove(store);
        });
      }),
    );
  }

  Future<void> _external(
    String id,
    Future<bool> Function() action,
    String error,
  ) async {
    if (_busy.contains(id)) return;
    setState(() => _busy.add(id));
    var opened = false;
    try {
      opened = await action();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _busy.remove(id));
    if (!opened) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Widget _spinner() => const SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.olive),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          surfaceTintColor: Colors.transparent,
          title: Text(
            l.storeCompare,
            maxLines: 2,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: TextField(
                  controller: _input,
                  maxLength: 100,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: l.groceryCompareSearch,
                    filled: true,
                    fillColor: const Color(0xFFFEFDF9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      tooltip: l.storeSearch,
                      onPressed: _load,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    Text(
                      l.groceryCompareIntro,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_results.isEmpty && _pending.isEmpty)
                      Text(l.storeSearchHelp),
                    for (final store in Supermarket.values)
                      if (_results.containsKey(store) ||
                          _pending.contains(store))
                        _storeCard(store, l),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        l.groceryDetails,
                        style: const TextStyle(fontSize: 13),
                      ),
                      children: [
                        Text(
                          l.storeCompareNote,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _storeCard(Supermarket store, AppLocalizations l) {
    final result = _results[store];
    final loading = _pending.contains(store);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFDF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  store.label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'Georgia',
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (loading) _spinner(),
              IconButton(
                key: ValueKey('store-map-${store.name}'),
                tooltip: l.storeNearby,
                onPressed: _busy.contains('map-${store.name}')
                    ? null
                    : () => _external(
                        'map-${store.name}',
                        () =>
                            widget.openMaps?.call(store, l.localeName) ??
                            NearbyStores.openForStore(
                              store.mapsQuery,
                              l.localeName,
                            ),
                        l.homeMapsUnavailable,
                      ),
                icon: _busy.contains('map-${store.name}')
                    ? _spinner()
                    : const Icon(
                        Icons.map_outlined,
                        size: 21,
                        color: AppColors.olive,
                      ),
              ),
            ],
          ),
          if (store == Supermarket.pricesmart)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l.storePriceSmartNote,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
            ),
          if (loading)
            Text(
              l.storeLoading,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            )
          else if (result?.unavailable == true) ...[
            Text(
              l.storeUnavailable,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            TextButton(onPressed: _load, child: Text(l.homeRetry)),
          ] else if (result?.offers.isEmpty ?? true) ...[
            Text(
              l.storeNoProducts,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 5),
            Text(
              l.groceryCompareEmpty,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
          for (final offer in result?.offers ?? <SupermarketOffer>[])
            _offer(offer, l),
        ],
      ),
    );
  }

  Widget _offer(SupermarketOffer offer, AppLocalizations l) {
    final item = GroceryItem(
      offer.product,
      ingredientId:
          (widget.ingredient ?? GroceryProduct.ingredient(_input.text))?.name,
    ).withOffer(offer);
    final eggPrice = groceryEggUnitPrice(item, l);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 14),
          Text(
            offer.product,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            groceryPackageLabel(item, l),
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Text(
            item.formatCents(offer.priceCents),
            style: const TextStyle(
              fontSize: 23,
              color: AppColors.olive,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (eggPrice != null)
            Text(
              eggPrice,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => Navigator.pop(context, offer),
            child: Text(l.storeUsePrice, textAlign: TextAlign.center),
          ),
          TextButton.icon(
            onPressed: _busy.contains(offer.sourceUrl)
                ? null
                : () => _external(
                    offer.sourceUrl,
                    () => launchUrl(
                      Uri.parse(offer.sourceUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    l.groceryReferenceError,
                  ),
            icon: _busy.contains(offer.sourceUrl)
                ? _spinner()
                : const Icon(Icons.open_in_new_rounded, size: 15),
            label: Text(
              l.storeViewProduct,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
