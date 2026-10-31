import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/groceries/data/grocery_price_estimator.dart';
import 'package:miga/core/theme/app_theme.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/groceries/presentation/sheets/grocery_price_editor.dart';
import 'package:miga/features/groceries/presentation/sheets/supermarket_comparison_page.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';
import 'package:miga/features/stores/data/nearby_stores.dart';
import 'package:miga/l10n/app_localizations.dart';

Future<List<GroceryItem>?> showGroceryList(
  BuildContext context,
  List<GroceryItem> items, {
  String currency = 'DOP',
  Future<SupermarketOffer?> Function(String)? estimate,
}) => showModalBottomSheet<List<GroceryItem>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: AppColors.cream,
  builder: (context) => Theme(
    data: AppTheme.household(Theme.of(context)),
    child: _GroceryList(items: items, currency: currency, estimate: estimate),
  ),
);

class _GroceryList extends StatefulWidget {
  const _GroceryList({
    required this.items,
    required this.currency,
    this.estimate,
  });
  final List<GroceryItem> items;
  final String currency;
  final Future<SupermarketOffer?> Function(String)? estimate;

  @override
  State<_GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<_GroceryList> {
  final _input = TextEditingController();
  late final _items = List<GroceryItem>.of(widget.items);

  final _estimator = GroceryPriceEstimator();
  final _loading = <String>{};
  final _manual = <String>{};
  final _attempted = <String>{};
  final _requests = <String, Future<void>>{};
  bool _saving = false;
  bool _added = false;

  @override
  void initState() {
    super.initState();
    unawaited(_estimateExisting());
  }

  Future<void> _estimateExisting() async {
    // Bound concurrent catalog lookups for longer shopping lists.
    final names = _items.map((item) => item.name).toList();
    for (var offset = 0; offset < names.length && mounted; offset += 2) {
      await Future.wait(names.skip(offset).take(2).map(_estimate));
    }
  }

  Future<void> _estimate(String name) {
    return _requests[name] ??= _estimateItem(name).whenComplete(() {
      _requests.remove(name);
    });
  }

  Future<void> _estimateItem(String name) async {
    final index = _items.indexWhere((item) => item.name == name);
    if (!mounted ||
        index < 0 ||
        _loading.contains(name) ||
        _manual.contains(name) ||
        _attempted.contains(name)) {
      return;
    }
    final original = _items[index];
    if (original.currency != 'DOP' ||
        (original.unitPriceCents != null &&
            !(original.offer?.isStale ?? false))) {
      return;
    }
    _attempted.add(name);
    setState(() => _loading.add(name));
    SupermarketOffer? offer;
    try {
      offer = await (widget.estimate ?? _estimator.estimate)(name);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _loading.remove(name);
      final current = _items.indexWhere((item) => item.name == name);
      if (current < 0 ||
          _manual.contains(name) ||
          offer == null ||
          offer.isStale) {
        return;
      }
      final item = _items[current];
      if (item.currency == original.currency &&
          item.unitPriceCents == original.unitPriceCents &&
          identical(item.offer, original.offer)) {
        _items[current] = item.withOffer(offer, estimated: true);
      }
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final name = _input.text.trim();
    if (name.isEmpty) return;
    var added = false;
    setState(() {
      if (!_items.any(
        (item) => item.name.toLowerCase() == name.toLowerCase(),
      )) {
        _items.add(GroceryItem(name, currency: widget.currency));
        added = true;
      }
      _input.clear();
    });
    if (added) setState(() => _added = true);
    unawaited(_estimate(name));
  }

  Future<void> _save() async {
    if (_input.text.trim().isNotEmpty) {
      _add();
      return;
    }
    setState(() => _saving = true);
    await _estimateExisting();
    if (mounted) Navigator.of(context).pop(List<GroceryItem>.of(_items));
  }

  Future<void> _editPrice(int index) async {
    final name = _items[index].name;
    _manual.add(name);
    final item = await showDialog<GroceryItem>(
      context: context,
      builder: (_) => GroceryPriceEditor(item: _items[index]),
    );
    if (!mounted || item == null) return;
    setState(() => _items[index] = item);
  }

  Future<void> _comparePrices() async {
    final index = _items.length == 1
        ? 0
        : await showDialog<int>(
            context: context,
            builder: (_) => _GroceryCompareItemDialog(items: _items),
          );
    if (!mounted || index == null) return;
    final offer = await showDialog<SupermarketOffer>(
      context: context,
      builder: (_) => SupermarketComparisonPage(
        query: _items[index].offer?.product ?? _items[index].name,
      ),
    );
    if (!mounted || offer == null) return;
    setState(() {
      _manual.add(_items[index].name);
      _items[index] = _items[index].withOffer(offer);
    });
  }

  Future<void> _storeMap(Supermarket store) async {
    var opened = false;
    try {
      opened = await NearbyStores.openForStore(
        store.mapsQuery,
        Localizations.localeOf(context).languageCode,
      );
    } catch (_) {}
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.homeMapsUnavailable),
        ),
      );
    }
  }

  Future<void> _openReferences() async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(
          'https://proconsumidor.gob.do/sondeo-de-precios-canasta-de-precios-justos/',
        ),
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
    final totals = GroceryTotals(_items, widget.currency);
    final money = GroceryItem('', currency: widget.currency);
    final checked = _items.where((item) => item.checked).length;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (context, controller) => Column(
          children: [
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  Text(
                    l10n.homeGroceryList,
                    style: const TextStyle(
                      fontFamily: 'LiberationSerif',
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.homeGroceryDescription,
                    style: const TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _items.isEmpty ? null : _comparePrices,
                    icon: const Icon(Icons.compare_arrows_rounded),
                    label: Text(l10n.storeCompare),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _input,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() => _added = false),
                    onSubmitted: (_) => _add(),
                    decoration: InputDecoration(
                      labelText: l10n.homeGroceryAdd,
                      hintText: l10n.homeGroceryHint,
                      suffixIcon: IconButton(
                        tooltip: l10n.homeGroceryAdd,
                        onPressed: _add,
                        icon: const Icon(Icons.add),
                      ),
                    ),
                  ),
                  if (_added)
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          l10n.groceryItemAdded,
                          style: const TextStyle(color: AppColors.olive),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (_items.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBEDDF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            totals.priced > 0
                                ? l10n.groceryEstimate(
                                    money.formatCents(totals.subtotalCents),
                                  )
                                : l10n.groceryPricesNeeded,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            totals.missing > 0
                                ? l10n.groceryPriceCoverage(
                                    totals.missing,
                                    widget.currency,
                                  )
                                : l10n.groceryEstimateNote,
                            style: const TextStyle(
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.groceryCartProgress(checked, _items.length),
                          ),
                          const SizedBox(height: 8),
                          TweenAnimationBuilder<double>(
                            tween: Tween(end: checked / _items.length),
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 220),
                            builder: (_, value, _) => LinearProgressIndicator(
                              value: value,
                              color: AppColors.olive,
                              backgroundColor: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Text(
                        l10n.homeGroceryEmpty,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  for (var index = 0; index < _items.length; index++) ...[
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: _items[index].checked,
                            title: Text(
                              _items[index].name,
                              style: TextStyle(
                                decoration: _items[index].checked
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: itemPriceLabel(_items[index], l10n),
                            onChanged: (value) => setState(
                              () => _items[index] = _items[index].withChecked(
                                value!,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          key: ValueKey('grocery-price-$index'),
                          onPressed: () => _editPrice(index),
                          child: Text(
                            _loading.contains(_items[index].name)
                                ? l10n.groceryEstimating
                                : (_items[index].offer?.isStale ?? false)
                                ? l10n.storeRefreshPrice
                                : _items[index].totalCents == null
                                ? l10n.groceryEstimateUnavailable
                                : '${_items[index].isEstimated ? '≈ ' : ''}${_items[index].formatCents(_items[index].totalCents!)}',
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.homeGroceryRemove,
                          onPressed: () =>
                              setState(() => _items.removeAt(index)),
                          icon: const Icon(Icons.close, size: 19),
                        ),
                      ],
                    ),
                    if (_items[index].offer != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () =>
                              _storeMap(_items[index].offer!.store),
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: Text(
                            '${_items[index].offer!.store.label} · ${l10n.storeNearby}',
                          ),
                        ),
                      ),
                  ],
                  TextButton.icon(
                    onPressed: _openReferences,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(l10n.groceryReferences),
                  ),
                  Text(
                    l10n.groceryReferenceNote,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(
                    _saving
                        ? l10n.groceryEstimating
                        : _input.text.trim().isNotEmpty
                        ? l10n.homeGroceryAdd
                        : l10n.homeSave,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? itemPriceLabel(GroceryItem item, AppLocalizations l10n) =>
      item.unitPriceCents == null
      ? null
      : Text(
          '${item.isEstimated ? '${l10n.groceryAutoEstimate}\n' : ''}${item.quantity} × ${item.formatCents(item.unitPriceCents!)} · ${item.offer != null
              ? '${item.offer!.presentation}\n${item.offer!.store.label} · ${item.offer!.observedAt.toLocal().toIso8601String().substring(0, 10)}'
              : item.reference == null
              ? l10n.groceryYourPrice
              : '${item.reference!.presentation} · ${item.reference!.month} ${item.reference!.year} · Pro Consumidor'}',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        );
}

class _GroceryCompareItemDialog extends StatelessWidget {
  const _GroceryCompareItemDialog({required this.items});

  final List<GroceryItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.storeChooseItem),
      content: SizedBox(
        width: 420,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            final price = item.unitPriceCents == null
                ? l10n.groceryEstimateUnavailable
                : item.formatCents(item.unitPriceCents!);
            return Material(
              color: const Color(0xFFF3F4EC),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.of(context).pop(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.olive,
                        foregroundColor: Colors.white,
                        child: Text('${index + 1}'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              price,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.olive,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }
}
