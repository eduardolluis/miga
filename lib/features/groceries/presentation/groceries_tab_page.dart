import 'package:flutter/material.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/core/ui/miga_ui_copy.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/groceries/presentation/widgets/grocery_pro_actions.dart';
import 'package:miga/features/groceries/presentation/widgets/grocery_price_summary.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
import 'package:miga/features/recipes/presentation/widgets/ingredient_image.dart';
import 'package:miga/l10n/app_localizations.dart';

/// Compact shopping list with recognizable ingredient illustrations and
/// optimistic, per-row checkbox feedback instead of a global page reload.
class GroceriesTabPage extends StatefulWidget {
  const GroceriesTabPage({
    super.key,
    required this.items,
    required this.onEdit,
    this.onToggle,
    this.onGenerate,
    this.onComplete,
    this.onCompare,
    this.onUpgrade,
    this.isPro = false,
    this.currency = 'DOP',
  });

  final List<GroceryItem> items;
  final Future<void> Function()? onEdit, onGenerate, onCompare, onComplete;
  final VoidCallback? onUpgrade;
  final bool isPro;
  final String currency;
  final Future<bool> Function(GroceryItem)? onToggle;

  @override
  State<GroceriesTabPage> createState() => _GroceriesTabPageState();
}

class _GroceriesTabPageState extends State<GroceriesTabPage> {
  final Map<int, bool> _pendingValues = {};
  final Set<int> _saving = {};
  bool _editing = false;
  bool _completing = false;

  Future<void> _complete() async {
    if (_completing || widget.onComplete == null || _saving.isNotEmpty) return;
    setState(() => _completing = true);
    try {
      await widget.onComplete!();
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _edit() async {
    if (_editing || widget.onEdit == null) return;
    setState(() => _editing = true);
    try {
      await widget.onEdit!();
    } finally {
      if (mounted) setState(() => _editing = false);
    }
  }

  Future<void> _toggle(int index) async {
    if (_saving.contains(index) || widget.onToggle == null) return;
    final item = widget.items[index];
    final desired = !(_pendingValues[index] ?? item.checked);
    setState(() {
      _pendingValues[index] = desired;
      _saving.add(index);
    });
    bool saved = false;
    try {
      saved = await widget.onToggle!(item.withChecked(desired));
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    setState(() {
      _pendingValues.remove(index);
      _saving.remove(index);
    });
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.homeSaveError)),
      );
    }
  }

  (String, String?) _display(String raw) {
    final text = raw.trim();
    final comma = RegExp(r'^(.+),\s*(\d+)\s*$').firstMatch(text);
    if (comma != null) return (comma.group(1)!, comma.group(2));
    final match = RegExp(
      r'^(\d+(?:[.,]\d+)?)\s+((?:(?:medium|large|small|cups?|tablespoons?|teaspoons?|tazas?|cucharadas?|pequeñas?|medianas?|grandes?)\s+)*)(.+)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      return (match.group(3)!, '${match.group(1)} ${match.group(2)}'.trim());
    }
    return (text, null);
  }

  RecipeIngredient? _ingredient(GroceryItem item, String displayed) {
    for (final value in RecipeIngredient.values) {
      if (item.ingredientId == value.name) return value;
    }
    final name = displayed.toLowerCase();
    if (name.contains('sweet potato') || name.contains('batata')) {
      return RecipeIngredient.sweetPotato;
    }
    for (final value in RecipeIngredient.values) {
      if (name == value.en.toLowerCase() ||
          name == value.es.toLowerCase() ||
          name.contains(value.en.toLowerCase()) ||
          name.contains(value.es.toLowerCase())) {
        return value;
      }
    }
    // Common human-entered words and inflections.
    if (name.contains('egg') || name.contains('huevo')) {
      return RecipeIngredient.eggs;
    }
    if (name.contains('potato') || name.contains('papa')) {
      return RecipeIngredient.potatoes;
    }
    if (name.contains('tomato') || name.contains('tomate')) {
      return RecipeIngredient.tomatoes;
    }
    if (name.contains('spinach') || name.contains('espinaca')) {
      return RecipeIngredient.spinach;
    }
    if (name.contains('oil') || name.contains('aceite')) {
      return RecipeIngredient.oliveOil;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final allChecked =
        widget.items.isNotEmpty && widget.items.every((item) => item.checked);
    final pendingCount = widget.items.where((item) => !item.checked).length;
    return ListView(
      key: const PageStorageKey('groceries-tab'),
      padding: const EdgeInsets.fromLTRB(22, 25, 22, 34),
      children: [
        Text(
          MigaUiCopy.shopping(context),
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 32,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          l.homeGroceryCount(pendingCount),
          style: const TextStyle(color: AppColors.muted, fontSize: 15),
        ),
        const SizedBox(height: 20),
        GroceryProActions(
          isPro: widget.isPro,
          onGenerate: widget.onGenerate,
          onCompare: widget.onCompare,
          onUpgrade: widget.onUpgrade,
        ),
        const SizedBox(height: 16),
        if (widget.items.isNotEmpty) ...[
          GroceryPriceSummary(
            items: [
              for (var i = 0; i < widget.items.length; i++)
                widget.items[i].withChecked(
                  _pendingValues[i] ?? widget.items[i].checked,
                ),
            ],
            currency: widget.currency,
          ),
          const SizedBox(height: 16),
        ],
        if (widget.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 55),
            child: Column(
              children: [
                const Icon(
                  Icons.shopping_basket_outlined,
                  size: 54,
                  color: AppColors.olive,
                ),
                const SizedBox(height: 14),
                Text(l.homeGroceryDescription, textAlign: TextAlign.center),
              ],
            ),
          ),
        for (var i = 0; i < widget.items.length; i++) ...[
          _shoppingRow(context, i),
          const SizedBox(height: 9),
        ],
        const SizedBox(height: 18),
        if (allChecked && widget.onComplete != null) ...[
          FilledButton.icon(
            key: const ValueKey('grocery-complete'),
            onPressed: _completing || _saving.isNotEmpty ? null : _complete,
            icon: _completing && ModalRoute.of(context)?.isCurrent != false
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(l.groceryComplete),
          ),
          const SizedBox(height: 10),
        ],
        FilledButton.icon(
          onPressed: _editing ? null : _edit,
          icon: _editing && ModalRoute.of(context)?.isCurrent != false
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.edit_note_rounded),
          label: Text(MigaUiCopy.openShopping(context)),
        ),
      ],
    );
  }

  Widget _shoppingRow(BuildContext context, int index) {
    final item = widget.items[index];
    final (name, amount) = _display(item.name);
    final ingredient = _ingredient(item, name);
    final checked = _pendingValues[index] ?? item.checked;
    final saving = _saving.contains(index);
    return AnimatedContainer(
      key: ValueKey('grocery-item-${item.ingredientId ?? item.name}'),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: checked ? const Color(0xFFE5ECDC) : const Color(0xFFFEFDF8),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: checked ? const Color(0xFFD0DFC8) : AppColors.line,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _toggle(index),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: saving
                    ? const SizedBox(
                        key: ValueKey('saving'),
                        width: 36,
                        height: 36,
                        child: Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.olive,
                          ),
                        ),
                      )
                    : Icon(
                        checked
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        key: ValueKey(checked),
                        color: AppColors.olive,
                        size: 36,
                      ),
              ),
            ),
            const SizedBox(width: 9),
            if (ingredient != null)
              IngredientImage(ingredient: ingredient, size: 49)
            else
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0DC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.eco_outlined, color: AppColors.olive),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _editing ? null : _edit,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: checked ? AppColors.muted : AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: checked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.offer != null
                          ? '${groceryPackageLabel(item, AppLocalizations.of(context)!)} · ${item.offer!.store.label}'
                          : amount == null
                          ? '×${item.quantity}'
                          : '$amount  ·  ×${item.quantity}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (item.totalCents != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '≈ ${item.formatCents(item.totalCents!)}',
                        style: const TextStyle(
                          color: AppColors.olive,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (groceryEggUnitPrice(item, AppLocalizations.of(context)!)
                        case final String unitPrice)
                      Text(
                        unitPrice,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
