import 'package:flutter/material.dart';
import 'package:miga/core/ui/miga_skeleton.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/groceries/data/dominican_price_source.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/groceries/domain/grocery_price_reference.dart';
import 'package:miga/l10n/app_localizations.dart';

class GroceryReferencePicker extends StatefulWidget {
  const GroceryReferencePicker({super.key, this.load});
  final Future<List<GroceryPriceReference>> Function()? load;

  @override
  State<GroceryReferencePicker> createState() => _GroceryReferencePickerState();
}

class _GroceryReferencePickerState extends State<GroceryReferencePicker> {
  late Future<List<GroceryPriceReference>> _request = _load();
  String _query = '';
  Future<List<GroceryPriceReference>> _load() =>
      widget.load?.call() ?? DominicanPriceSource.instance.load();

  String _normalize(String text) {
    var result = text.toLowerCase();
    for (final entry in {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ñ': 'n',
    }.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result.trim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.groceryReferenceTitle),
      content: SizedBox(
        width: 500,
        height: MediaQuery.sizeOf(context).height * 0.55,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.groceryReferenceDisclaimer,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: l10n.groceryReferenceSearch,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            FutureBuilder<List<GroceryPriceReference>>(
              future: _request,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SliverToBoxAdapter(
                    child: SkeletonRows(count: 4),
                  );
                }
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Text(l10n.groceryReferenceUnavailable),
                        TextButton(
                          onPressed: () => setState(() => _request = _load()),
                          child: Text(l10n.homeRetry),
                        ),
                      ],
                    ),
                  );
                }
                final terms = _normalize(_query).split(RegExp(r'\s+'));
                final items = (snapshot.data ?? [])
                    .where(
                      (item) => terms.every(
                        (term) =>
                            _normalize('${item.product} ${item.presentation}')
                                .contains(term),
                      ),
                    )
                    .toList();
                const months = [
                  'enero',
                  'febrero',
                  'marzo',
                  'abril',
                  'mayo',
                  'junio',
                  'julio',
                  'agosto',
                  'septiembre',
                  'octubre',
                  'noviembre',
                  'diciembre',
                ];
                items.sort(
                  (a, b) => (b.year * 12 + months.indexOf(_normalize(b.month)))
                      .compareTo(
                        a.year * 12 + months.indexOf(_normalize(a.month)),
                      ),
                );
                if (items.isEmpty) {
                  return SliverToBoxAdapter(child: Text(l10n.recipeNoResults));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${item.product} · ${GroceryItem('').formatCents(item.priceCents)}',
                      ),
                      subtitle: Text(
                        '${item.presentation}\n${item.segment}\n${item.month} ${item.year}\n${l10n.groceryUseReference}',
                      ),
                      isThreeLine: true,
                      onTap: () => Navigator.of(context).pop(item),
                    );
                  }, childCount: items.length),
                );
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.groceryReferenceAttribution,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ),
            ),
          ],
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
