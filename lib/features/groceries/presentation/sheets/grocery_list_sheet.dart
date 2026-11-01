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
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/groceries/domain/grocery_product.dart';
import 'package:miga/features/groceries/presentation/widgets/grocery_pro_actions.dart';
import 'package:miga/features/groceries/presentation/widgets/grocery_price_summary.dart';
import 'package:miga/features/recipes/presentation/widgets/ingredient_image.dart';

Future<List<GroceryItem>?> showGroceryList(
  BuildContext context,
  List<GroceryItem> items, {
  String currency = 'DOP',
  Future<SupermarketOffer?> Function(String)? estimate,
  List<GroceryItem> Function(List<GroceryItem>)? onGenerateFromPlan,
  bool syncWithPlan = false,
  bool allowEstimates = true,
  bool isPro = false,
  VoidCallback? onUpgrade,
  Future<bool> Function(List<GroceryItem>)? onComplete,
  ValueChanged<bool>? onSyncChanged,
}) => showModalBottomSheet<List<GroceryItem>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: AppColors.cream,
  builder: (context) => Theme(
    data: AppTheme.household(Theme.of(context)),
    child: _GroceryList(
      items: items,
      currency: currency,
      estimate: estimate,
      onGenerateFromPlan: onGenerateFromPlan,
      syncWithPlan: syncWithPlan,
      allowEstimates: allowEstimates,
      isPro: isPro,
      onUpgrade: onUpgrade,
      onComplete: onComplete,
      onSyncChanged: onSyncChanged,
    ),
  ),
);

class _GroceryList extends StatefulWidget {
  const _GroceryList({
    required this.items,
    required this.currency,
    this.estimate,
    this.onGenerateFromPlan,
    this.syncWithPlan = false,
    this.allowEstimates = true,
    this.isPro = false,
    this.onUpgrade,
    this.onComplete,
    this.onSyncChanged,
  });
  final List<GroceryItem> items;
  final String currency;
  final Future<SupermarketOffer?> Function(String)? estimate;
  final List<GroceryItem> Function(List<GroceryItem>)? onGenerateFromPlan;
  final bool syncWithPlan;
  final bool allowEstimates;
  final bool isPro;
  final VoidCallback? onUpgrade;
  final Future<bool> Function(List<GroceryItem>)? onComplete;
  final ValueChanged<bool>? onSyncChanged;

  @override
  State<_GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<_GroceryList> {
  final _input = TextEditingController();
  late final _items = widget.items
      .map((item) => item.normalizedForPricing())
      .toList();

  final _estimator = GroceryPriceEstimator();
  final _loading = <String>{};
  final _manual = <String>{};
  final _attempted = <String>{};
  final _requests = <String, Future<void>>{};
  bool _saving = false;
  bool _added = false;
  late bool _syncPlan = widget.isPro && widget.syncWithPlan;

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
        !widget.allowEstimates ||
        index < 0 ||
        _loading.contains(name) ||
        _manual.contains(name) ||
        _attempted.contains(name)) {
      return;
    }
    var original = _items[index];
    if (original.currency != 'DOP' ||
        (original.unitPriceCents != null &&
            !(original.offer?.isStale ?? false) &&
            !original.hasInvalidEstimate)) {
      return;
    }
    if (original.hasInvalidEstimate) {
      original = original.withoutPrice();
      setState(() => _items[index] = original);
    }
    _attempted.add(name);
    setState(() => _loading.add(name));
    SupermarketOffer? offer;
    try {
      offer = widget.estimate != null
          ? await widget.estimate!(name)
          : await _estimator.estimate(
              name,
              ingredient: original.ingredientForPricing,
            );
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
        _items.add(
          GroceryItem(name, currency: widget.currency).normalizedForPricing(),
        );
        added = true;
      }
      _input.clear();
    });
    if (added) setState(() => _added = true);
    unawaited(_estimate(name));
  }

  Future<void> _generateFromPlan() async {
    if (!widget.isPro) {
      widget.onUpgrade?.call();
      return;
    }
    if (widget.onGenerateFromPlan == null || _saving) return;
    final items = widget.onGenerateFromPlan!(List<GroceryItem>.of(_items));
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      if (widget.onSyncChanged != null) _syncPlan = true;
      _items
        ..clear()
        ..addAll(items);
    });
    widget.onSyncChanged?.call(_syncPlan);
    await _estimateExisting();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          items.where((item) => item.fromPlan).isEmpty
              ? l10n.groceryNothingNeeded
              : l10n.groceryGeneratedCount(
                  items.where((item) => item.fromPlan).length,
                ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_input.text.trim().isNotEmpty) {
      _add();
      return;
    }
    setState(() => _saving = true);
    await _estimateExisting();
    if (mounted) Navigator.of(context).pop(List<GroceryItem>.of(_items));
  }

  Future<void> _complete() async {
    if (_saving || widget.onComplete == null) return;
    setState(() => _saving = true);
    final success = await widget.onComplete!(List.of(_items));
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
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
    if (!widget.isPro) {
      widget.onUpgrade?.call();
      return;
    }
    final updated = await compareGroceryItems(context, List.of(_items));
    if (!mounted || updated == null) return;
    setState(() {
      for (final item in updated) {
        final index = _items.indexWhere((old) => old.name == item.name);
        if (index >= 0 && !identical(_items[index].offer, item.offer)) {
          _manual.add(item.name);
          _items[index] = item;
        }
      }
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
    final l = AppLocalizations.of(context)!;
    final complete =
        _items.isNotEmpty &&
        _items.every((item) => item.checked) &&
        widget.onComplete != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .85,
        maxChildSize: .95,
        minChildSize: .4,
        builder: (context, controller) => Column(
          children: [
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  Text(
                    l.homeGroceryList,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 28,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.groceryEditorIntro,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _input,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() => _added = false),
                    onSubmitted: (_) => _add(),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: l.homeGroceryAdd,
                      suffixIcon: IconButton(
                        tooltip: l.homeGroceryAdd,
                        onPressed: _saving ? null : _add,
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
                          l.groceryItemAdded,
                          style: const TextStyle(
                            color: AppColors.olive,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_items.isNotEmpty) ...[
                    GroceryPriceSummary(
                      items: _items,
                      currency: widget.currency,
                      loading: _loading.isNotEmpty,
                    ),
                    const SizedBox(height: 18),
                  ],
                  GroceryProActions(
                    isPro: widget.isPro,
                    onUpgrade: widget.onUpgrade,
                    onGenerate: widget.onGenerateFromPlan == null
                        ? null
                        : _generateFromPlan,
                    onCompare: _items.isEmpty ? null : _comparePrices,
                  ),
                  const SizedBox(height: 20),
                  if (_items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Text(
                        l.homeGroceryEmpty,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  for (var index = 0; index < _items.length; index++)
                    _itemCard(index, l),
                  if (widget.isPro && widget.onSyncChanged != null)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l.syncGroceriesLabel,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        l.syncGroceriesNote,
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _syncPlan,
                      onChanged: _saving
                          ? null
                          : (value) {
                              setState(() => _syncPlan = value);
                              widget.onSyncChanged!(value);
                              if (value) unawaited(_generateFromPlan());
                            },
                    ),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      l.groceryDetails,
                      style: const TextStyle(fontSize: 13),
                    ),
                    children: [
                      Text(
                        l.groceryEstimateNote,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _openReferences,
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: Text(
                          l.groceryReferences,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving
                        ? null
                        : complete
                        ? _complete
                        : _save,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_saving &&
                            ModalRoute.of(context)?.isCurrent != false) ...[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: Text(
                            _saving
                                ? l.groceryEstimating
                                : complete
                                ? l.groceryComplete
                                : _input.text.trim().isNotEmpty
                                ? l.homeGroceryAdd
                                : l.homeSave,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(int index, AppLocalizations l) {
    final item = _items[index];
    final ingredient = item.ingredientForPricing;
    final eggPrice = groceryEggUnitPrice(item, l);
    final price = _loading.contains(item.name)
        ? l.groceryEstimating
        : item.totalCents == null
        ? l.groceryEstimateUnavailable
        : '${item.isEstimated ? '≈ ' : ''}${item.formatCents(item.totalCents!)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFDF9),
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Checkbox(
                key: ValueKey('grocery-check-$index'),
                value: item.checked,
                onChanged: _saving
                    ? null
                    : (value) => setState(
                        () => _items[index] = _items[index].withChecked(value!),
                      ),
              ),
              if (ingredient != null) ...[
                IngredientImage(ingredient: ingredient, size: 40),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  ingredient?.label(l.localeName) ?? item.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: item.checked
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              IconButton(
                tooltip: l.homeGroceryRemove,
                onPressed: _saving
                    ? null
                    : () => setState(() => _items.removeAt(index)),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          if (item.requiredAmount != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Text(
                '${l.requiredAmountLabel}: ${item.requiredAmount!.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')} ${switch (item.requiredUnit) {
                  CostUnit.grams => 'g',
                  CostUnit.milliliters => 'ml',
                  _ => l.budgetPieces,
                }}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Text(
              '${groceryPackageLabel(item, l)}${item.offer == null ? '' : ' · ${item.offer!.store.label}'}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
          if (eggPrice != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                eggPrice,
                style: const TextStyle(fontSize: 12, color: AppColors.olive),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final controls = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l.groceryDecrease,
                    icon: const Icon(Icons.remove_circle_outline, size: 21),
                    onPressed: _saving || item.quantity <= 1
                        ? null
                        : () => setState(
                            () => _items[index] = _items[index].withQuantity(
                              _items[index].quantity - 1,
                            ),
                          ),
                  ),
                  Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    tooltip: l.groceryIncrease,
                    icon: const Icon(Icons.add_circle_outline, size: 21),
                    onPressed: _saving || item.quantity >= 9999
                        ? null
                        : () => setState(
                            () => _items[index] = _items[index].withQuantity(
                              _items[index].quantity + 1,
                            ),
                          ),
                  ),
                ],
              );
              final amount = TextButton(
                key: ValueKey('grocery-price-$index'),
                onPressed: _saving ? null : () => _editPrice(index),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_loading.contains(item.name)) ...[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        price,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (constraints.maxWidth < 280 ||
                  MediaQuery.textScalerOf(context).scale(14) > 21) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [controls, amount],
                );
              }
              return Row(
                children: [
                  controls,
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: amount,
                    ),
                  ),
                ],
              );
            },
          ),
          if (item.offer != null)
            Material(
              color: Colors.transparent,
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Text(
                  l.groceryDetails,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [
                  Text(
                    item.offer!.product,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                  TextButton.icon(
                    onPressed: () => _storeMap(item.offer!.store),
                    icon: const Icon(Icons.map_outlined, size: 17),
                    label: Text(l.storeNearby),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Future<List<GroceryItem>?> compareGroceryItems(
  BuildContext context,
  List<GroceryItem> items, {
  Future<List<StoreSearchResult>> Function(String)? search,
}) async {
  final index = items.length == 1
      ? 0
      : await showDialog<int>(
          context: context,
          builder: (_) => _GroceryCompareItemDialog(items: items),
        );
  if (!context.mounted || index == null) return null;
  final item = items[index].normalizedForPricing();
  final ingredient = item.ingredientForPricing;
  final offer = await showDialog<SupermarketOffer>(
    context: context,
    builder: (_) => SupermarketComparisonPage(
      query: ingredient?.es ?? GroceryProduct.name(item.name),
      ingredient: ingredient,
      search: search,
    ),
  );
  if (offer == null) return null;
  final updated = List<GroceryItem>.of(items);
  updated[index] = item.withOffer(offer);
  return updated;
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
                                fontSize: 13,
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
