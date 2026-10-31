import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:miga/core/theme/app_colors.dart';
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
}) => showModalBottomSheet<List<GroceryItem>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: AppColors.cream,
  builder: (context) => Theme(
    data: AppTheme.household(Theme.of(context)),
    child: _GroceryList(items: items, currency: currency),
  ),
);

class _GroceryList extends StatefulWidget {
  const _GroceryList({required this.items, required this.currency});
  final List<GroceryItem> items;
  final String currency;

  @override
  State<_GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<_GroceryList> {
  final _input = TextEditingController();
  late final _items = List<GroceryItem>.of(widget.items);

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final name = _input.text.trim();
    if (name.isEmpty) return;
    setState(() {
      if (!_items.any(
        (item) => item.name.toLowerCase() == name.toLowerCase(),
      )) {
        _items.add(GroceryItem(name, currency: widget.currency));
      }
      _input.clear();
    });
  }

  Future<void> _editPrice(int index) async {
    final item = await showDialog<GroceryItem>(
      context: context,
      builder: (_) => GroceryPriceEditor(item: _items[index]),
    );
    if (!mounted || item == null) return;
    setState(() => _items[index] = item);
  }

  Future<void> _comparePrices() async {
    final l10n = AppLocalizations.of(context)!;
    final index = _items.length == 1
        ? 0
        : await showDialog<int>(
            context: context,
            builder: (context) => SimpleDialog(
              title: Text(l10n.storeChooseItem),
              children: [
                for (var i = 0; i < _items.length; i++)
                  SimpleDialogOption(
                    onPressed: () => Navigator.of(context).pop(i),
                    child: Text(_items[i].name),
                  ),
              ],
            ),
          );
    if (!mounted || index == null) return;
    final offer = await showDialog<SupermarketOffer>(
      context: context,
      builder: (_) => SupermarketComparisonPage(
        query: _items[index].offer?.product ?? _items[index].name,
      ),
    );
    if (!mounted || offer == null) return;
    setState(() => _items[index] = _items[index].withOffer(offer));
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
                            (_items[index].offer?.isStale ?? false)
                                ? l10n.storeRefreshPrice
                                : _items[index].totalCents == null
                                ? l10n.groceryAddPrice
                                : _items[index].formatCents(
                                    _items[index].totalCents!,
                                  ),
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
                  onPressed: () {
                    _add();
                    Navigator.of(context).pop(List<GroceryItem>.of(_items));
                  },
                  child: Text(l10n.homeSave),
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
          '${item.quantity} × ${item.formatCents(item.unitPriceCents!)} · ${item.offer != null
              ? '${item.offer!.presentation}\n${item.offer!.store.label} · ${item.offer!.observedAt.toLocal().toIso8601String().substring(0, 10)}'
              : item.reference == null
              ? l10n.groceryYourPrice
              : '${item.reference!.presentation} · ${item.reference!.month} ${item.reference!.year} · Pro Consumidor'}',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        );
}
