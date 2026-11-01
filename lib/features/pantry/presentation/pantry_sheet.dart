import 'package:flutter/material.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/pantry/domain/pantry_item.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
import 'package:miga/l10n/app_localizations.dart';

Future<List<PantryItem>?> showPantry(
  BuildContext context,
  List<PantryItem> items,
) => showModalBottomSheet<List<PantryItem>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => _PantrySheet(items),
);

class _PantrySheet extends StatefulWidget {
  const _PantrySheet(this.items);
  final List<PantryItem> items;
  @override
  State<_PantrySheet> createState() => _PantrySheetState();
}

class _PantrySheetState extends State<_PantrySheet> {
  late final _amounts = {
    for (final ingredient in RecipeIngredient.values)
      ingredient: TextEditingController(
        text:
            widget.items
                .where((p) => p.ingredient == ingredient)
                .firstOrNull
                ?.amount
                .toString() ??
            '',
      ),
  };
  late final _units = {
    for (final ingredient in RecipeIngredient.values)
      ingredient:
          widget.items
              .where((p) => p.ingredient == ingredient)
              .firstOrNull
              ?.unit ??
          RecipeAmounts.unitFor(ingredient),
  };
  bool _invalid = false;

  void _save() {
    final items = <PantryItem>[];
    for (final entry in _amounts.entries) {
      final text = entry.value.text.trim().replaceAll(',', '.');
      if (text.isEmpty) continue;
      final value = double.tryParse(text);
      if (value == null || !value.isFinite || value < 0 || value > 1000000) {
        setState(() => _invalid = true);
        return;
      }
      if (value > 0) {
        items.add(PantryItem(entry.key, value, _units[entry.key]!));
      }
    }
    Navigator.pop(context, items);
  }

  @override
  void dispose() {
    for (final controller in _amounts.values) {
      controller.dispose();
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
                    l.pantryTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(l.pantryEmpty),
                  const SizedBox(height: 20),
                  for (final ingredient in RecipeIngredient.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        key: ValueKey('pantry-${ingredient.name}'),
                        controller: _amounts[ingredient],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: ingredient.label(l.localeName),
                          hintText: '0',
                          suffixText: switch (_units[ingredient]!) {
                            CostUnit.grams => 'g',
                            CostUnit.milliliters => 'ml',
                            CostUnit.pieces => l.budgetPieces,
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
                      l.amountInvalid,
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
