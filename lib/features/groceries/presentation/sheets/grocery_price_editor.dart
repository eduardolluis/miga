import 'package:miga/core/region/supported_regions.dart';
import 'package:flutter/material.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/groceries/domain/grocery_price_reference.dart';
import 'package:miga/features/groceries/presentation/sheets/grocery_reference_picker.dart';
import 'package:miga/features/groceries/presentation/sheets/supermarket_comparison_page.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';
import 'package:miga/l10n/app_localizations.dart';

class GroceryPriceEditor extends StatefulWidget {
  const GroceryPriceEditor({super.key, required this.item});
  final GroceryItem item;

  @override
  State<GroceryPriceEditor> createState() => _GroceryPriceEditorState();
}

class _GroceryPriceEditorState extends State<GroceryPriceEditor> {
  final _form = GlobalKey<FormState>();
  late final _price = TextEditingController(
    text: widget.item.unitPriceCents == null
        ? ''
        : (widget.item.unitPriceCents! / 100).toStringAsFixed(2),
  );
  late final _quantity = TextEditingController(text: '${widget.item.quantity}');
  late String _currency = widget.item.currency;
  late GroceryPriceReference? _reference = widget.item.reference;
  late SupermarketOffer? _offer = widget.item.offer;

  Future<void> _compare() async {
    final offer = await showDialog<SupermarketOffer>(
      context: context,
      builder: (_) => SupermarketComparisonPage(
        query:
            widget.item.offer?.product ??
            widget.item.reference?.product ??
            widget.item.name,
      ),
    );
    if (!mounted || offer == null) return;
    setState(() {
      _offer = offer;
      _reference = null;
      _price.text = (offer.priceCents / 100).toStringAsFixed(2);
      _currency = offer.currency;
    });
  }

  Future<void> _findReference() async {
    final reference = await showDialog<GroceryPriceReference>(
      context: context,
      builder: (_) => const GroceryReferencePicker(),
    );
    if (!mounted || reference == null) return;
    setState(() {
      _reference = reference;
      _offer = null;
      _price.text = (reference.priceCents / 100).toStringAsFixed(2);
      _currency = reference.currency;
    });
  }

  @override
  void dispose() {
    _price.dispose();
    _quantity.dispose();
    super.dispose();
  }

  int? get _cents {
    final value = _price.text.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d{1,7}(\.\d{1,2})?$').hasMatch(value)) return null;
    final parts = value.split('.');
    return int.parse(parts[0]) * 100 +
        int.parse(parts.length == 1 ? '0' : parts[1].padRight(2, '0'));
  }

  void _save({bool removePrice = false}) {
    if (removePrice) {
      Navigator.of(context).pop(
        GroceryItem(
          widget.item.name,
          checked: widget.item.checked,
          currency: widget.item.currency,
          quantity: widget.item.quantity,
          ingredientId: widget.item.ingredientId,
          requiredAmount: widget.item.requiredAmount,
          requiredUnit: widget.item.requiredUnit,
          manualQuantity: widget.item.manualQuantity,
          planGenerated: widget.item.planGenerated,
        ),
      );
      return;
    }
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(
      GroceryItem(
        widget.item.name,
        checked: widget.item.checked,
        currency: _currency,
        quantity: int.tryParse(_quantity.text) ?? widget.item.quantity,
        unitPriceCents: removePrice ? null : _cents,
        reference: _reference,
        offer: _offer,
        ingredientId: widget.item.ingredientId,
        requiredAmount: widget.item.requiredAmount,
        requiredUnit: widget.item.requiredUnit,
        manualQuantity: true,
        planGenerated: widget.item.planGenerated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.item.name),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _offer != null
                    ? l10n.storeOnlinePrice
                    : _reference == null
                    ? l10n.groceryManualPrice
                    : l10n.groceryReferencePrice,
              ),
              TextButton.icon(
                onPressed: _compare,
                icon: const Icon(Icons.compare_arrows_rounded),
                label: Text(l10n.storeCompare),
              ),
              if (_offer != null)
                Text('${_offer!.store.label} · ${_offer!.presentation}'),
              TextButton.icon(
                onPressed: _findReference,
                icon: const Icon(Icons.search, size: 18),
                label: Text(l10n.groceryFindReference),
              ),
              if (_reference != null)
                Text(
                  '${_reference!.product} · ${_reference!.presentation}\n${_reference!.month} ${_reference!.year} · ${_reference!.segment}',
                ),
              const SizedBox(height: 20),
              TextFormField(
                key: const ValueKey('grocery-unit-price'),
                controller: _price,
                onChanged: (_) => setState(() {
                  _reference = null;
                  _offer = null;
                }),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: l10n.groceryUnitPrice),
                validator: (_) => (_offer?.isStale ?? false)
                    ? l10n.storeRefreshPrice
                    : _cents == null
                    ? l10n.groceryPriceInvalid
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('grocery-quantity'),
                controller: _quantity,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.groceryQuantity),
                validator: (value) {
                  final quantity = int.tryParse(value ?? '');
                  return quantity == null || quantity < 1 || quantity > 999
                      ? l10n.groceryQuantityInvalid
                      : null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('grocery-currency-$_currency'),
                initialValue: _currency,
                decoration: InputDecoration(labelText: l10n.homeCurrency),
                items: [
                  for (final code in SupportedRegions.currencies)
                    DropdownMenuItem(
                      value: code,
                      child: Text('$code · ${SupportedRegions.symbol(code)}'),
                    ),
                ],
                onChanged: (value) => setState(() {
                  if (value != _currency) _price.clear();
                  _currency = value!;
                  _reference = null;
                  _offer = null;
                }),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.item.unitPriceCents != null)
          TextButton(
            onPressed: () => _save(removePrice: true),
            child: Text(l10n.groceryRemovePrice),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.homeSave)),
      ],
    );
  }
}
