import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/groceries/data/supermarket_price_source.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';
import 'package:miga/features/stores/data/nearby_stores.dart';
import 'package:miga/l10n/app_localizations.dart';

class SupermarketComparisonPage extends StatefulWidget {
  const SupermarketComparisonPage({
    super.key,
    required this.query,
    this.search,
    this.openMaps,
  });
  final String query;
  final Future<List<StoreSearchResult>> Function(String)? search;
  final Future<bool> Function(Supermarket, String)? openMaps;

  @override
  State<SupermarketComparisonPage> createState() =>
      _SupermarketComparisonPageState();
}

class _SupermarketComparisonPageState extends State<SupermarketComparisonPage> {
  late final _input = TextEditingController(text: widget.query);
  final _source = SupermarketPriceSource();
  late Future<List<StoreSearchResult>> _request = _search();
  Future<List<StoreSearchResult>> _search() =>
      (widget.search ?? _source.search)(_input.text);

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _maps(Supermarket store) async {
    final language = Localizations.localeOf(context).languageCode;
    var opened = false;
    try {
      opened =
          await (widget.openMaps?.call(store, language) ??
              NearbyStores.openForStore(store.mapsQuery, language));
    } catch (_) {}
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.homeMapsUnavailable),
        ),
      );
    }
  }

  Future<void> _product(SupermarketOffer offer) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(offer.sourceUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.groceryReferenceError),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: Text(l10n.storeCompare),
          backgroundColor: AppColors.cream,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          top: false,
          child: FutureBuilder<List<StoreSearchResult>>(
            future: _request,
            builder: (context, snapshot) => ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                TextField(
                  controller: _input,
                  maxLength: 100,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => setState(() => _request = _search()),
                  decoration: InputDecoration(
                    hintText: l10n.groceryReferenceSearch,
                    suffixIcon: IconButton(
                      tooltip: l10n.storeSearch,
                      onPressed: () => setState(() => _request = _search()),
                      icon: const Icon(Icons.search),
                    ),
                  ),
                ),
                Text(
                  l10n.storeCompareNote,
                  style: const TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState != ConnectionState.done)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  Text(l10n.storeUnavailable)
                else if ((snapshot.data ?? []).isEmpty)
                  Text(l10n.storeSearchHelp)
                else
                  for (final result in snapshot.data!) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            result.store.label,
                            style: const TextStyle(
                              fontFamily: 'LiberationSerif',
                              fontSize: 27,
                            ),
                          ),
                        ),
                        IconButton(
                          key: ValueKey('store-map-${result.store.name}'),
                          tooltip: l10n.storeNearby,
                          onPressed: () => _maps(result.store),
                          icon: const Icon(
                            Icons.map_outlined,
                            color: AppColors.olive,
                          ),
                        ),
                      ],
                    ),
                    if (result.store == Supermarket.pricesmart)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          l10n.storePriceSmartNote,
                          style: const TextStyle(
                            color: AppColors.muted,
                            height: 1.5,
                          ),
                        ),
                      ),
                    if (result.unavailable)
                      Text(
                        l10n.storeUnavailable,
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      )
                    else if (result.offers.isEmpty)
                      Text(l10n.storeNoProducts),
                    for (final offer in result.offers)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEFDF9),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              offer.product,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (offer.presentation != offer.product)
                              Text(
                                offer.presentation,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  height: 1.4,
                                ),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              GroceryItem(
                                '',
                                currency: offer.currency,
                              ).formatCents(offer.priceCents),
                              style: const TextStyle(
                                color: AppColors.olive,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.storeObserved(
                                '${dates.formatShortDate(offer.observedAt.toLocal())} '
                                '${dates.formatTimeOfDay(TimeOfDay.fromDateTime(offer.observedAt.toLocal()))}',
                              ),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(offer),
                              child: Text(l10n.storeUsePrice),
                            ),
                            TextButton(
                              onPressed: () => _product(offer),
                              child: Text(l10n.storeViewProduct),
                            ),
                          ],
                        ),
                      ),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
