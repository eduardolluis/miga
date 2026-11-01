import 'package:flutter/material.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/core/ui/miga_ui_copy.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
import 'package:miga/features/recipes/presentation/widgets/ingredient_image.dart';
import 'package:miga/l10n/app_localizations.dart';

class RecipeFilters {
  const RecipeFilters({
    this.cheap = false,
    this.quick = false,
    this.protein = false,
    this.favorites = false,
    this.pantry = false,
    this.ingredients = const {},
  });
  final bool cheap, quick, protein, favorites, pantry;
  final Set<RecipeIngredient> ingredients;
}

class RecipeFiltersSheet extends StatefulWidget {
  const RecipeFiltersSheet({
    super.key,
    required this.initial,
    required this.hasBudget,
    this.onPantry,
  });
  final RecipeFilters initial;
  final bool hasBudget;
  final VoidCallback? onPantry;

  @override
  State<RecipeFiltersSheet> createState() => _RecipeFiltersSheetState();
}

class _RecipeFiltersSheetState extends State<RecipeFiltersSheet> {
  late bool _cheap = widget.initial.cheap,
      _quick = widget.initial.quick,
      _protein = widget.initial.protein,
      _favorites = widget.initial.favorites,
      _pantry = widget.initial.pantry;
  late final _ingredients = {...widget.initial.ingredients};
  String _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
    _cheap = _quick = _protein = _favorites = _pantry = false;
    _ingredients.clear();
    _query = '';
    _search.clear();
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final ingredients =
        RecipeIngredient.values
            .where(
              (i) => i
                  .label(language)
                  .toLowerCase()
                  .contains(_query.toLowerCase().trim()),
            )
            .toList()
          ..sort((a, b) => a.label(language).compareTo(b.label(language)));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .88,
      minChildSize: .5,
      maxChildSize: .96,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    MigaUiCopy.filters(context),
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 28,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('filters-close'),
                  tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              children: [
                Text(
                  l.recipeFiltersIntro,
                  style: const TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 24),
                Text(
                  l.recipeFilterPreferences,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 14),
                Material(
                  color: const Color(0xFFFEFDF9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: AppColors.line),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile.adaptive(
                    key: const ValueKey('filter-budget'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    secondary: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.olive,
                    ),
                    title: Text(
                      l.cheapFilter,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: widget.hasBudget
                        ? null
                        : Text(
                            MigaUiCopy.budgetUnknown(context),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                    value: _cheap,
                    onChanged: widget.hasBudget
                        ? (v) => setState(() => _cheap = v)
                        : null,
                    activeTrackColor: AppColors.olive,
                  ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width =
                        MediaQuery.textScalerOf(context).scale(14) > 20
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 10) / 2;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: width,
                          child: _FilterOption(
                            optionKey: const ValueKey('filter-quick'),
                            label: l.quickFilter,
                            icon: Icons.timer_outlined,
                            selected: _quick,
                            onTap: () => setState(() => _quick = !_quick),
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _FilterOption(
                            optionKey: const ValueKey('filter-protein'),
                            label: l.proteinFilter,
                            icon: Icons.fitness_center_rounded,
                            selected: _protein,
                            onTap: () => setState(() => _protein = !_protein),
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _FilterOption(
                            optionKey: const ValueKey('filter-favorites'),
                            label: l.favoritesFilter,
                            icon: Icons.favorite_border_rounded,
                            selected: _favorites,
                            onTap: () =>
                                setState(() => _favorites = !_favorites),
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _FilterOption(
                            optionKey: const ValueKey('filter-pantry'),
                            label: l.pantryFilter,
                            icon: Icons.kitchen_outlined,
                            selected: _pantry,
                            onTap: () => setState(() => _pantry = !_pantry),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.recipeHaveIngredients,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (_ingredients.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '${_ingredients.length}',
                          style: const TextStyle(
                            color: AppColors.olive,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l.recipeIngredientsHint,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const ValueKey('filter-ingredient-search'),
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: l.recipeIngredientSearch,
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xFFEFEDE6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (ingredients.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l.recipeNoIngredients),
                  ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns =
                        MediaQuery.textScalerOf(context).scale(14) > 20
                        ? 1
                        : constraints.maxWidth > 560
                        ? 3
                        : 2;
                    final width =
                        (constraints.maxWidth - 10 * (columns - 1)) / columns;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final i in ingredients)
                          SizedBox(
                            width: width,
                            child: _FilterOption(
                              optionKey: ValueKey('ingredient-${i.name}'),
                              label: i.label(language),
                              ingredient: i,
                              selected: _ingredients.contains(i),
                              onTap: () => setState(() {
                                if (!_ingredients.add(i)) {
                                  _ingredients.remove(i);
                                }
                              }),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                if (widget.onPantry != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onPantry!();
                      },
                      icon: const Icon(Icons.kitchen_outlined),
                      label: Text(l.pantryTitle),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    key: const ValueKey('filters-apply'),
                    onPressed: () => Navigator.of(context).pop(
                      RecipeFilters(
                        cheap: _cheap,
                        quick: _quick,
                        protein: _protein,
                        favorites: _favorites,
                        pantry: _pantry,
                        ingredients: {..._ingredients},
                      ),
                    ),
                    child: Text(l.recipeShowResults),
                  ),
                  TextButton(
                    key: const ValueKey('filters-reset'),
                    onPressed: _reset,
                    child: Text(l.recipeResetFilters),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    required this.optionKey,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.ingredient,
  });
  final Key optionKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final RecipeIngredient? ingredient;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      key: optionKey,
      color: selected ? const Color(0xFFE3ECD9) : const Color(0xFFFEFDF9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? AppColors.olive : AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (ingredient != null)
                  IngredientImage(ingredient: ingredient!, size: 30)
                else
                  Icon(
                    selected ? Icons.check_circle_rounded : icon,
                    size: 22,
                    color: AppColors.olive,
                  ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (selected && ingredient != null)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.olive,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
