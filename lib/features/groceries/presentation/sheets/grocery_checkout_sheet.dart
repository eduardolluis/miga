import 'package:flutter/material.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/core/theme/app_theme.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/l10n/app_localizations.dart';

class GroceryCheckout {
  const GroceryCheckout(this.paidTotalCents);
  final int? paidTotalCents;
}

Future<GroceryCheckout?> showGroceryCheckout(
  BuildContext context,
  List<GroceryItem> items,
  String currency,
) => showModalBottomSheet<GroceryCheckout>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: AppColors.cream,
  builder: (context) => Theme(
    data: AppTheme.household(Theme.of(context)),
    child: _Checkout(items: items, currency: currency),
  ),
);

class _Checkout extends StatefulWidget {
  const _Checkout({required this.items, required this.currency});
  final List<GroceryItem> items;
  final String currency;
  @override
  State<_Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<_Checkout> {
  final _amount = TextEditingController();
  bool _invalid = false;
  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _complete() {
    final raw = _amount.text.trim().replaceAll(',', '.');
    if (raw.isNotEmpty && !RegExp(r'^\d{1,7}(?:\.\d{1,2})?$').hasMatch(raw)) {
      setState(() => _invalid = true);
      return;
    }
    final cents = raw.isEmpty ? null : (double.parse(raw) * 100).round();
    Navigator.pop(context, GroceryCheckout(cents));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final totals = GroceryTotals(
      widget.items,
      widget.currency,
      includeBudgetEstimates: true,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 34,
                  color: AppColors.olive,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.groceryComplete,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 27,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l.groceryCompleteNote,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l.groceryEstimate(
                  '${totals.estimated > 0 ? '≈ ' : ''}${GroceryItem('', currency: widget.currency).formatCents(totals.subtotalCents)}',
                ),
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              if (totals.missing > 0)
                Text(
                  l.groceryPricesMissing(totals.missing),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              const SizedBox(height: 14),
              TextField(
                key: const ValueKey('checkout-paid-total'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _complete(),
                decoration: InputDecoration(
                  labelText: l.groceryPaidTotal,
                  prefixText: '${widget.currency} ',
                  hintText: '0.00',
                  helperText: l.groceryPaidTotalHint,
                  helperMaxLines: 3,
                  errorText: _invalid ? l.groceryPriceInvalid : null,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                key: const ValueKey('checkout-confirm'),
                onPressed: _complete,
                child: Text(l.groceryComplete),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.cancelAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
