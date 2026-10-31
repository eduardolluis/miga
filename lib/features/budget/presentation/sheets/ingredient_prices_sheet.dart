import 'package:flutter/material.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
import 'package:miga/l10n/app_localizations.dart';

Future<Map<String, int>?> showIngredientPrices(
  BuildContext context,
  String currency,
  Map<String, int> prices,
) => showModalBottomSheet<Map<String, int>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => _PricesSheet(currency, prices),
);

class _PricesSheet extends StatefulWidget {
  const _PricesSheet(this.currency, this.prices);
  final String currency;
  final Map<String, int> prices;
  @override
  State<_PricesSheet> createState() => _PricesSheetState();
}

class _PricesSheetState extends State<_PricesSheet> {
  late final _inputs = {
    for (final ingredient in RecipeIngredient.values)
      ingredient: TextEditingController(
        text: widget.prices['${widget.currency}:${ingredient.name}'] == null
            ? ''
            : (widget.prices['${widget.currency}:${ingredient.name}']! / 100)
                  .toStringAsFixed(2),
      ),
  };
  bool _invalid = false;
  void _save() {
    final prices = {...widget.prices};
    for (final entry in _inputs.entries) {
      final key = '${widget.currency}:${entry.key.name}';
      final text = entry.value.text.trim().replaceAll(',', '.');
      if (text.isEmpty) {
        prices.remove(key);
        continue;
      }
      if (!RegExp(r'^\d{1,7}(\.\d{1,2})?$').hasMatch(text)) {
        setState(() => _invalid = true);
        return;
      }
      prices[key] = (double.parse(text) * 100).round();
    }
    Navigator.pop(context, prices);
  }

  @override
  void dispose() {
    for (final input in _inputs.values) {
      input.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .9,
        builder: (context, scroll) => Column(
          children: [
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    l.priceSettingsTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(l.priceSettingsNote),
                  const SizedBox(height: 20),
                  for (final ingredient in RecipeIngredient.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        key: ValueKey('price-${ingredient.name}'),
                        controller: _inputs[ingredient],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: ingredient.label(l.localeName),
                          prefixText: '${widget.currency} ',
                          suffixText: switch (RecipeAmounts.values.values
                              .expand((a) => a)
                              .firstWhere((a) => a.ingredient == ingredient)
                              .unit) {
                            CostUnit.grams => '/ kg',
                            CostUnit.milliliters => '/ L',
                            CostUnit.pieces => '/ ${l.budgetPieces}',
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_invalid)
                    Text(
                      l.groceryPriceInvalid,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  FilledButton(onPressed: _save, child: Text(l.homeSave)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
