import 'dart:async';

import 'package:flutter/material.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/budget/application/recipe_cost_estimator.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/pantry/domain/pantry_item.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/presentation/widgets/ingredient_image.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_detail_photo.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_nutrition_panel.dart';
import 'package:miga/features/recipes/presentation/widgets/favorite_heart_icon.dart';
import 'package:miga/l10n/app_localizations.dart';

Future<Recipe?> showRecipeDetails(
  BuildContext context,
  Recipe recipe, {
  Future<bool> Function(List<String>)? onAddIngredients,
  Future<bool> Function(List<RecipeAmount>)? onAddAmounts,
  List<PantryItem> pantry = const [],
  Future<List<PantryItem>?> Function(RecipeAmount, bool)? onPantryChanged,
  RecipeCost Function(Recipe)? costFor,
  Map<String, int> manualPrices = const {},
  WeeklyBudget? budget,
  String currency = 'DOP',
  DateTime? now,
  String? planLabel,
  bool favorite = false,
  Future<bool> Function()? onToggleFavorite,
  Future<bool> Function(int)? onServingsChanged,
  Future<void> Function()? onEditPrices,
  Future<void> Function(Recipe)? onRefreshPrices,
}) => showModalBottomSheet<Recipe>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: false,
  backgroundColor: AppColors.cream,
  builder: (_) => _RecipeDetails(
    recipe: recipe,
    onAddIngredients: onAddIngredients,
    onAddAmounts: onAddAmounts,
    pantry: pantry,
    onPantryChanged: onPantryChanged,
    costFor: costFor,
    manualPrices: manualPrices,
    budget: budget,
    currency: currency,
    now: now,
    planLabel: planLabel,
    favorite: favorite,
    onToggleFavorite: onToggleFavorite,
    onServingsChanged: onServingsChanged,
    onEditPrices: onEditPrices,
    onRefreshPrices: onRefreshPrices,
  ),
);

class _RecipeDetails extends StatefulWidget {
  const _RecipeDetails({
    required this.recipe,
    this.onAddIngredients,
    this.onAddAmounts,
    this.pantry = const [],
    this.onPantryChanged,
    this.costFor,
    this.manualPrices = const {},
    this.budget,
    this.currency = 'DOP',
    this.now,
    this.planLabel,
    this.favorite = false,
    this.onToggleFavorite,
    this.onServingsChanged,
    this.onEditPrices,
    this.onRefreshPrices,
  });
  final Recipe recipe;
  final Future<bool> Function(List<String>)? onAddIngredients;
  final Future<bool> Function(List<RecipeAmount>)? onAddAmounts;
  final List<PantryItem> pantry;
  final Future<List<PantryItem>?> Function(RecipeAmount, bool)? onPantryChanged;
  final RecipeCost Function(Recipe)? costFor;
  final Map<String, int> manualPrices;
  final WeeklyBudget? budget;
  final String currency;
  final DateTime? now;
  final String? planLabel;
  final bool favorite;
  final Future<bool> Function()? onToggleFavorite;
  final Future<bool> Function(int)? onServingsChanged;
  final Future<void> Function()? onEditPrices;
  final Future<void> Function(Recipe)? onRefreshPrices;

  @override
  State<_RecipeDetails> createState() => _RecipeDetailsState();
}

class _RecipeDetailsState extends State<_RecipeDetails> {
  final Set<int> _checked = {};
  late List<PantryItem> _pantry = List.of(widget.pantry);
  late int _servings = widget.recipe.servings;
  late bool _favorite = widget.favorite;
  bool _favoriteSaving = false, _updating = false, _adding = false;
  bool _added = false, _failed = false;
  int _tab = 0;

  bool _pricing = false;

  @override
  void initState() {
    super.initState();
    if (widget.onRefreshPrices != null &&
        widget.costFor?.call(_recipe).complete != true) {
      unawaited(_refreshPrices());
    }
  }

  Future<void> _refreshPrices() async {
    setState(() => _pricing = true);
    try {
      await widget.onRefreshPrices?.call(_recipe);
    } catch (_) {}
    if (mounted) setState(() => _pricing = false);
  }

  Recipe get _recipe => widget.recipe.withServings(_servings);
  List<RecipeAmount> get _amounts => RecipeAmounts.forRecipe(_recipe);

  double _missing(RecipeAmount amount) {
    var remaining = amount.amount;
    for (final stock in _pantry.where(
      (item) => item.ingredient == amount.ingredient,
    )) {
      if (stock.unit == amount.unit) remaining -= stock.amount;
      if (stock.unit == CostUnit.grams &&
          amount.unit == CostUnit.pieces &&
          amount.gramsPerPiece != null) {
        remaining -= stock.amount / amount.gramsPerPiece!;
      }
    }
    return remaining.clamp(0, amount.amount);
  }

  bool _atHome(int index) =>
      _checked.contains(index) || _missing(_amounts[index]) <= .000001;

  String _amountLabel(RecipeAmount amount, AppLocalizations l) {
    final n = amount.amount
        .toStringAsFixed(1)
        .replaceFirst(RegExp(r'\.0$'), '');
    final unit = switch (amount.unit) {
      CostUnit.grams => 'g',
      CostUnit.milliliters => 'ml',
      CostUnit.pieces => l.budgetPieces,
    };
    return '$n $unit';
  }

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
    List<PantryItem>? pantry;
    try {
      pantry = await widget.onPantryChanged!(_amounts[index], available);
    } catch (_) {
      pantry = null;
    }
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

  Future<void> _changeServings(int value) async {
    if (_adding || _updating) return;
    setState(() => _updating = true);
    bool success = false;
    try {
      success = await widget.onServingsChanged?.call(value) ?? true;
    } catch (_) {
      success = false;
    }
    if (!mounted) return;
    setState(() {
      _updating = false;
      _failed = !success;
      if (success) {
        _servings = value;
        _added = false;
      }
    });
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteSaving || widget.onToggleFavorite == null) return;
    setState(() {
      _favorite = !_favorite;
      _favoriteSaving = true;
    });
    bool success = false;
    try {
      success = await widget.onToggleFavorite!();
    } catch (_) {
      success = false;
    }
    if (!mounted) return;
    setState(() {
      _favoriteSaving = false;
      if (!success) {
        _favorite = !_favorite;
        _failed = true;
      }
    });
  }

  Future<void> _addMissing() async {
    if (_adding || _updating) return;
    final amounts = _amounts;
    final missing = [
      for (var i = 0; i < amounts.length; i++)
        if (!_atHome(i))
          RecipeAmount(
            amounts[i].ingredient,
            _missing(amounts[i]),
            amounts[i].unit,
            gramsPerPiece: amounts[i].gramsPerPiece,
          ),
    ];
    if (missing.isEmpty) return;
    setState(() {
      _adding = true;
      _failed = false;
    });
    bool success = false;
    try {
      if (widget.onAddAmounts != null) {
        success = await widget.onAddAmounts!(missing);
      } else if (widget.onAddIngredients != null) {
        final l = AppLocalizations.of(context)!;
        success = await widget.onAddIngredients!([
          for (final amount in missing)
            '${_amountLabel(amount, l)} ${amount.ingredient.label(l.localeName)}',
        ]);
      }
    } catch (_) {
      success = false;
    }
    if (!mounted) return;
    setState(() {
      _adding = false;
      _added = success;
      _failed = !success;
    });
  }

  String? _purchaseLabel(IngredientCost? cost, RecipeAmount amount) {
    final offer = cost?.offer;
    if (offer != null && !offer.isStale) {
      return offer.presentation.trim().isEmpty
          ? '${cost?.purchaseCount ?? 1} × ${offer.product}'
          : '${cost?.purchaseCount ?? 1} × ${offer.presentation}';
    }
    // Legacy manual prices are stored per kg, liter, or piece. Their unit
    // must be shown honestly until the user links a store presentation.
    final key = '${widget.currency}:${amount.ingredient.name}';
    if (widget.manualPrices[key] != null) {
      return switch (amount.unit) {
        CostUnit.grams => '${cost?.purchaseCount ?? 1} × 1 kg (precio manual)',
        CostUnit.milliliters =>
          '${cost?.purchaseCount ?? 1} × 1 L (precio manual)',
        CostUnit.pieces =>
          '${cost?.purchaseCount ?? 1} × 1 unidad (precio manual)',
      };
    }
    return null;
  }

  String? _purchasePrice(
    IngredientCost? cost,
    RecipeAmount amount,
    WeeklyBudget budget,
  ) {
    if (cost?.cents != null) return budget.format(cost!.cents! / 100);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final spanish = locale == 'es';
    final recipe = _recipe;
    final amounts = _amounts;
    final content = recipe.contentFor(locale);
    final cost = widget.costFor?.call(recipe);
    final money = WeeklyBudget(limit: 0, spent: 0, currency: widget.currency);
    final countAtHome = List.generate(
      amounts.length,
      (i) => i,
    ).where(_atHome).length;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .96,
      minChildSize: .48,
      maxChildSize: 1,
      builder: (context, scroll) => Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: RecipeDetailPhoto(photo: recipe.photo),
                        ),
                        if (widget.onToggleFavorite != null)
                          Positioned(
                            top: 7,
                            right: 7,
                            child: IconButton.filledTonal(
                              onPressed: _favoriteSaving
                                  ? null
                                  : _toggleFavorite,
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xEBFFFFFF),
                              ),
                              icon: FavoriteHeartIcon(
                                favorite: _favorite,
                                inactiveColor: AppColors.ink,
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      content.title,
                      style: const TextStyle(
                        fontSize: 25,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 17,
                      runSpacing: 6,
                      children: [
                        _info(
                          Icons.schedule_outlined,
                          l.recipeMinutes(recipe.minutes),
                        ),
                        _info(
                          Icons.restaurant_outlined,
                          l.recipeServings(_servings),
                        ),
                        _info(
                          Icons.soup_kitchen_outlined,
                          spanish ? 'Fácil de preparar' : 'Easy to prepare',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.servingsLabel,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_updating)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          DropdownButton<int>(
                            key: const ValueKey('recipe-servings'),
                            value: _servings,
                            underline: const SizedBox.shrink(),
                            items: [
                              for (var n = 1; n <= 24; n++)
                                DropdownMenuItem(value: n, child: Text('$n')),
                            ],
                            onChanged: _adding
                                ? null
                                : (value) => _changeServings(value!),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          for (var i = 0; i < 3; i++)
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  color: _tab == i
                                      ? AppColors.olive
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: InkWell(
                                  key: ValueKey('recipe-tab-$i'),
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: () => setState(() => _tab = i),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 11,
                                    ),
                                    child: Text(
                                      i == 0
                                          ? l.homeIngredients
                                          : i == 1
                                          ? l.homePreparation
                                          : (spanish
                                                ? 'Nutrición'
                                                : 'Nutrition'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _tab == i
                                            ? Colors.white
                                            : AppColors.ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_tab == 0) ...[
                      Text(
                        spanish
                            ? 'Ingredientes y precios'
                            : 'Ingredients & prices',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        l.recipePantryBreakdown(
                          amounts.length,
                          countAtHome,
                          amounts.length - countAtHome,
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < amounts.length; i++)
                        _ingredientRow(
                          context,
                          i,
                          amounts[i],
                          cost != null && i < cost.ingredients.length
                              ? cost.ingredients[i]
                              : null,
                          money,
                          l,
                        ),
                      const SizedBox(height: 15),
                      if (cost != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: const Color(0xFFE8F1D9),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shopping_cart_outlined,
                                color: AppColors.olive,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cost.complete
                                      ? (spanish
                                            ? 'Costo estimado de lo utilizado'
                                            : 'Estimated cost of ingredients used')
                                      : (spanish
                                            ? 'Precio incompleto: consulta los faltantes'
                                            : 'Incomplete prices: update missing items'),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              if (cost.complete)
                                Text(
                                  '≈ ${money.format(cost.subtotalCents / 100)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.olive,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 7),
                      Text(
                        spanish
                            ? 'El precio de compra depende del tamaño del paquete o envase.'
                            : 'Checkout cost depends on the full package or container size.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (widget.onAddAmounts != null ||
                          widget.onAddIngredients != null)
                        OutlinedButton.icon(
                          onPressed:
                              _adding ||
                                  _updating ||
                                  _added ||
                                  countAtHome == amounts.length
                              ? null
                              : _addMissing,
                          icon: _adding
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _added
                                      ? Icons.check_circle_outline
                                      : Icons.add_shopping_cart,
                                ),
                          label: Text(
                            _added
                                ? l.recipeIngredientsAdded
                                : l.recipeAddMissingToGroceries(
                                    amounts.length - countAtHome,
                                  ),
                          ),
                        ),
                    ],
                    if (_tab == 1) ...[
                      Text(
                        content.description,
                        style: const TextStyle(height: 1.45),
                      ),
                      const SizedBox(height: 18),
                      for (var i = 0; i < content.steps.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFFE4EFDB),
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: AppColors.olive,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  content.steps[i],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    if (_tab == 2)
                      RecipeNutritionPanel(
                        nutrition: recipe.nutrition,
                        servings: _servings,
                      ),
                    if (_failed) ...[
                      const SizedBox(height: 10),
                      Text(
                        l.homeSaveError,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                ),
                Positioned(
                  top: 19,
                  left: 25,
                  child: IconButton.filledTonal(
                    key: const ValueKey('recipe-back'),
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xEBFFFFFF),
                    ),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              7,
              18,
              MediaQuery.viewInsetsOf(context).bottom > 0 ? 10 : 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _adding || _updating
                    ? null
                    : () => Navigator.of(context).pop(_recipe),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: Text(widget.planLabel ?? l.homeUseRecipe),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: AppColors.ink),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.ink),
        ),
      ),
    ],
  );

  Widget _ingredientRow(
    BuildContext context,
    int i,
    RecipeAmount amount,
    IngredientCost? line,
    WeeklyBudget money,
    AppLocalizations l,
  ) {
    final price = _purchasePrice(line, amount, money);
    final presentation = _purchaseLabel(line, amount);
    final locale = Localizations.localeOf(context).languageCode;
    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              key: ValueKey('recipe-ingredient-${amount.ingredient.name}'),
              value: _atHome(i),
              onChanged: _adding || _updating
                  ? null
                  : (value) => _setAtHome(i, value ?? false),
              activeColor: AppColors.olive,
            ),
            IngredientImage(ingredient: amount.ingredient, size: 47),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    amount.ingredient.label(locale),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _amountLabel(amount, l),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                  if (presentation != null)
                    Text(
                      presentation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (price != null)
              Container(
                constraints: const BoxConstraints(maxWidth: 116),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F2D9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  price,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.olive,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              )
            else
              Flexible(
                child: Text(
                  _pricing ? l.groceryEstimating : l.groceryEstimateUnavailable,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
          ],
        ),
        const Divider(color: AppColors.line, height: 13),
      ],
    );
  }
}
