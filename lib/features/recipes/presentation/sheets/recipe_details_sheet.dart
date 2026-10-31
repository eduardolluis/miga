import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_image.dart';
import 'package:miga/l10n/app_localizations.dart';

Future<bool?> showRecipeDetails(
  BuildContext context,
  Recipe recipe, {
  Future<bool> Function()? onAddIngredients,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: AppColors.cream,
  builder: (_) =>
      _RecipeDetails(recipe: recipe, onAddIngredients: onAddIngredients),
);

class _RecipeDetails extends StatefulWidget {
  const _RecipeDetails({required this.recipe, required this.onAddIngredients});
  final Recipe recipe;
  final Future<bool> Function()? onAddIngredients;

  @override
  State<_RecipeDetails> createState() => _RecipeDetailsState();
}

class _RecipeDetailsState extends State<_RecipeDetails> {
  final _checked = <int>{};
  bool _adding = false;
  bool _added = false;
  bool _failed = false;

  Future<void> _addIngredients() async {
    setState(() {
      _adding = true;
      _failed = false;
    });
    final success = await widget.onAddIngredients!();
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
    final recipe = widget.recipe;
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
          const SizedBox(height: 10),
          for (var index = 0; index < content.ingredients.length; index++)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _checked.contains(index),
              title: Text(content.ingredients[index]),
              onChanged: (value) => setState(() {
                if (value == true) {
                  _checked.add(index);
                } else {
                  _checked.remove(index);
                }
              }),
            ),
          if (widget.onAddIngredients != null)
            OutlinedButton.icon(
              onPressed: _adding || _added ? null : _addIngredients,
              icon: Icon(_added ? Icons.check : Icons.shopping_basket_outlined),
              label: Text(
                _added
                    ? l10n.recipeIngredientsAdded
                    : l10n.recipeAddIngredients,
              ),
            ),
          if (_adding) const LinearProgressIndicator(),
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
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.homeUseRecipe),
          ),
        ],
      ),
    );
  }
}
