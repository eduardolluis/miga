import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/pantry/domain/pantry_item.dart';
import 'package:miga/features/home/presentation/widgets/recipe_cost_sheet.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_image.dart';
import 'package:miga/l10n/app_localizations.dart';

Future<Recipe?> showRecipeDetails(
  BuildContext context,
  Recipe recipe, {
  Future<bool> Function(List<String>)? onAddIngredients,
  Future<bool> Function(List<RecipeAmount>)? onAddAmounts,
  List<PantryItem> pantry = const [],
  Future<List<PantryItem>?> Function(RecipeAmount, bool)? onPantryChanged,
  RecipeCost Function(Recipe)? costFor,
  WeeklyBudget? budget,
  String currency = 'DOP',
  DateTime? now,
  String? planLabel,
  bool favorite = false,
  Future<bool> Function()? onToggleFavorite,
  Future<bool> Function(int)? onServingsChanged,
  Future<void> Function()? onEditPrices,
}) => showModalBottomSheet<Recipe>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: AppColors.cream,
  builder: (_) => _RecipeDetails(
    recipe: recipe,
    onAddIngredients: onAddIngredients,
    onAddAmounts: onAddAmounts,
    pantry: pantry,
    onPantryChanged: onPantryChanged,
    costFor: costFor,
    budget: budget,
    currency: currency,
    now: now,
    planLabel: planLabel,
    favorite: favorite,
    onToggleFavorite: onToggleFavorite,
    onServingsChanged: onServingsChanged,
    onEditPrices: onEditPrices,
  ),
);

class _RecipeDetails extends StatefulWidget {
  const _RecipeDetails({
    required this.recipe,
    required this.onAddIngredients,
    this.onAddAmounts,
    this.pantry = const [],
    this.onPantryChanged,
    this.costFor,
    this.budget,
    this.currency = 'DOP',
    this.now,
    this.planLabel,
    this.favorite = false,
    this.onToggleFavorite,
    this.onServingsChanged,
    this.onEditPrices,
  });
  final Recipe recipe;
  final Future<bool> Function(List<String>)? onAddIngredients;
  final Future<bool> Function(List<RecipeAmount>)? onAddAmounts;
  final List<PantryItem> pantry;
  final Future<List<PantryItem>?> Function(RecipeAmount, bool)? onPantryChanged;
  final RecipeCost Function(Recipe)? costFor;
  final WeeklyBudget? budget;
  final String currency;
  final DateTime? now;
  final String? planLabel;
  final bool favorite;
  final Future<bool> Function()? onToggleFavorite;
  final Future<bool> Function(int)? onServingsChanged;
  final Future<void> Function()? onEditPrices;

  @override
  State<_RecipeDetails> createState() => _RecipeDetailsState();
}

class _RecipeDetailsState extends State<_RecipeDetails> {
  final _checked = <int>{};
  late List<PantryItem> _pantry = List.of(widget.pantry);
  late int _servings = widget.recipe.servings;
  late bool _favorite = widget.favorite;
  bool _updating = false;
  Recipe get _recipe => widget.recipe.withServings(_servings);
  List<RecipeAmount> get _amounts => RecipeAmounts.forRecipe(_recipe);
  double _missing(RecipeAmount amount) {
    var value = amount.amount;
    for (final stock in _pantry.where(
      (p) => p.ingredient == amount.ingredient,
    )) {
      if (stock.unit == amount.unit) value -= stock.amount;
      if (stock.unit == CostUnit.grams &&
          amount.unit == CostUnit.pieces &&
          amount.gramsPerPiece != null) {
        value -= stock.amount / amount.gramsPerPiece!;
      }
    }
    return value.clamp(0, amount.amount);
  }

  bool _atHome(int index) =>
      _checked.contains(index) || _missing(_amounts[index]) <= .000001;

  Future<void> _setAtHome(int index, bool available) async {
    if (_adding || _updating) return;
    if (widget.onPantryChanged == null) {
      setState(() {
        if (available) {
          _checked.add(index);
        } else {
          _checked.remove(index);
        }
        _added = false;
        _failed = false;
      });
      return;
    }
    setState(() => _updating = true);
    final pantry = await widget.onPantryChanged!(_amounts[index], available);
    if (!mounted) return;
    setState(() {
      _updating = false;
      _failed = pantry == null;
      if (pantry != null) {
        _pantry = pantry;
        _added = false;
      }
    });
  }

  String _amountLabel(RecipeAmount amount, AppLocalizations l) {
    final value = amount.amount
        .toStringAsFixed(1)
        .replaceFirst(RegExp(r'\.0$'), '');
    final unit = switch (amount.unit) {
      CostUnit.grams => 'g',
      CostUnit.milliliters => 'ml',
      CostUnit.pieces => l.budgetPieces,
    };
    return '$value $unit ${amount.ingredient.label(l.localeName)}';
  }

  Future<void> _changeServings(int value) async {
    setState(() => _updating = true);
    final saved = await widget.onServingsChanged?.call(value) ?? true;
    if (!mounted) return;
    setState(() {
      _updating = false;
      _failed = !saved;
      if (saved) {
        _servings = value;
        _added = false;
      }
    });
  }

  Future<void> _toggleFavorite() async {
    if (_updating) return;
    setState(() => _updating = true);
    final saved = await widget.onToggleFavorite?.call() ?? false;
    if (!mounted) return;
    setState(() {
      _updating = false;
      _failed = !saved;
      if (saved) _favorite = !_favorite;
    });
  }

  bool _adding = false;
  bool _added = false;
  bool _failed = false;

  Future<void> _addIngredients() async {
    final l = AppLocalizations.of(context)!;
    final missing = [
      for (var i = 0; i < _amounts.length; i++)
        if (!_atHome(i))
          RecipeAmount(
            _amounts[i].ingredient,
            _missing(_amounts[i]),
            _amounts[i].unit,
            gramsPerPiece: _amounts[i].gramsPerPiece,
          ),
    ];
    if (missing.isEmpty) return;
    setState(() {
      _adding = true;
      _failed = false;
    });
    final success = widget.onAddAmounts != null
        ? await widget.onAddAmounts!(missing)
        : await widget.onAddIngredients!(
            missing.map((a) => _amountLabel(a, l)).toList(),
          );
    if (!mounted) return;
    setState(() {
      _adding = false;
      _added = success;
      _failed = !success;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final recipe = _recipe;
    final amounts = _amounts;
    final have = List.generate(amounts.length, (i) => i).where(_atHome).length;
    final cost = widget.costFor?.call(recipe);
    final money = WeeklyBudget(limit: 0, spent: 0, currency: widget.currency);
    final content = recipe.contentFor(
      Localizations.localeOf(context).languageCode,
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.4,
      maxChildSize: 0.96,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 190,
              child: RecipeImage(index: recipe.imageIndex),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            content.title,
            style: const TextStyle(
              fontFamily: 'LiberationSerif',
              fontSize: 30,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${l10n.recipeMinutes(recipe.minutes)} · ${l10n.recipeServings(recipe.servings)}',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            key: const ValueKey('recipe-servings'),
            initialValue: _servings,
            decoration: InputDecoration(labelText: l10n.servingsLabel),
            items: [
              for (var n = 1; n <= 24; n++)
                DropdownMenuItem(value: n, child: Text('$n')),
            ],
            onChanged: _updating || _adding
                ? null
                : (value) => _changeServings(value!),
          ),
          if (widget.onToggleFavorite != null)
            TextButton.icon(
              onPressed: _updating ? null : _toggleFavorite,
              icon: Icon(_favorite ? Icons.favorite : Icons.favorite_border),
              label: Text(_favorite ? l10n.favoriteRemove : l10n.favoriteAdd),
            ),
          if (cost != null) ...[
            Text(
              cost.complete
                  ? l10n.budgetRecipeEstimate
                  : l10n.budgetKnownSubtotal,
            ),
            Text(
              '≈ ${money.format(cost.subtotalCents / 100)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (cost.complete)
              Text(
                l10n.recipeCostPerServing(
                  money.format(cost.perServingCents / 100),
                ),
              ),
            if (widget.budget != null &&
                widget.budget!.currency == widget.currency &&
                cost.complete &&
                cost.subtotalCents >
                    mealAllowanceCents(
                      widget.budget!,
                      widget.now ?? DateTime.now(),
                    ))
              Text(
                l10n.budgetRecipeOver,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                showDragHandle: true,
                builder: (_) => RecipeCostSheet(cost: cost, budget: money),
              ),
              child: Text(l10n.budgetCostDetails),
            ),
            if (widget.onEditPrices != null)
              TextButton(
                onPressed: () async {
                  await widget.onEditPrices!();
                  if (mounted) setState(() {});
                },
                child: Text(l10n.priceSettingsTitle),
              ),
          ],
          if (recipe.nutrition != null) ...[
            Text(l10n.nutritionPerServing),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EBDF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    size: 18,
                    color: AppColors.olive,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.recipeNutrition(
                        recipe.nutrition!.calories,
                        recipe.nutrition!.proteinGrams,
                        recipe.nutrition!.carbsGrams,
                      ),
                      style: const TextStyle(
                        color: AppColors.olive,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (recipe.nutrition != null) ...[
            Text(l10n.nutritionTotal),
            Text(
              l10n.recipeNutrition(
                recipe.nutrition!.calories * _servings,
                recipe.nutrition!.proteinGrams * _servings,
                recipe.nutrition!.carbsGrams * _servings,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            content.description,
            style: const TextStyle(color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.homeIngredients,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.recipePantryBreakdown(
                amounts.length,
                have,
                amounts.length - have,
              ),
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < amounts.length; index++)
            CheckboxListTile(
              key: ValueKey(
                'recipe-ingredient-${amounts[index].ingredient.name}',
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _atHome(index),
              title: Text(_amountLabel(amounts[index], l10n)),
              subtitle: Text(
                _atHome(index)
                    ? '✓ ${l10n.recipeAtHome}'
                    : '🛒 ${l10n.recipeToBuy}',
                style: TextStyle(
                  fontSize: 13,
                  color: _atHome(index) ? AppColors.olive : AppColors.muted,
                ),
              ),
              onChanged: _adding || _updating
                  ? null
                  : (value) => _setAtHome(index, value!),
            ),
          if (widget.onAddIngredients != null || widget.onAddAmounts != null)
            OutlinedButton.icon(
              onPressed:
                  _adding || _updating || _added || have == amounts.length
                  ? null
                  : _addIngredients,
              icon: Icon(_added ? Icons.check : Icons.shopping_basket_outlined),
              label: Text(
                _added
                    ? l10n.recipeIngredientsAdded
                    : l10n.recipeAddMissingToGroceries(amounts.length - have),
              ),
            ),
          if (_adding || _updating) const LinearProgressIndicator(),
          if (_failed) Text(l10n.homeSaveError),
          const SizedBox(height: 28),
          Text(
            l10n.homePreparation,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < content.steps.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: const Color(0xFFE5E9DC),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.olive,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      content.steps[index],
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.olive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            onPressed: _adding || _updating
                ? null
                : () => Navigator.of(context).pop(_recipe),
            child: Text(widget.planLabel ?? l10n.homeUseRecipe),
          ),
        ],
      ),
    );
  }
}
