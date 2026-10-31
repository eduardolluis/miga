import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/l10n/app_localizations.dart';

Future<List<GroceryItem>?> showGroceryList(
  BuildContext context,
  List<GroceryItem> items,
) => showModalBottomSheet<List<GroceryItem>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: AppColors.cream,
  builder: (_) => _GroceryList(items: items),
);

class _GroceryList extends StatefulWidget {
  const _GroceryList({required this.items});
  final List<GroceryItem> items;

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
        _items.add(GroceryItem(name));
      }
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (context, controller) => ListView(
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
            const SizedBox(height: 20),
            TextField(
              controller: _input,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _add(),
              decoration: InputDecoration(
                labelText: l10n.homeGroceryAdd,
                hintText: l10n.homeGroceryHint,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: l10n.homeGroceryAdd,
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                ),
              ),
            ),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  l10n.homeGroceryEmpty,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
            for (var index = 0; index < _items.length; index++)
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
                      onChanged: (value) => setState(
                        () => _items[index] = GroceryItem(
                          _items[index].name,
                          checked: value!,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.homeGroceryRemove,
                    onPressed: () => setState(() => _items.removeAt(index)),
                    icon: const Icon(Icons.close, size: 19),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                _add();
                Navigator.of(context).pop(List<GroceryItem>.of(_items));
              },
              child: Text(l10n.homeSave),
            ),
          ],
        ),
      ),
    );
  }
}
