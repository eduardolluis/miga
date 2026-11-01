import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/meal_plan/presentation/meal_slot_presentation.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_image.dart';
import 'package:miga/l10n/app_localizations.dart';

class MealHeroCard extends StatelessWidget {
  const MealHeroCard({
    super.key,
    required this.recipe,
    required this.onOpen,
    required this.onPlan,
  });
  final Recipe recipe;
  final VoidCallback? onOpen;
  final VoidCallback? onPlan;

  static const titleStyle = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 24,
    height: 1.12,
    color: AppColors.ink,
  );
  static const metaStyle = TextStyle(
    fontSize: 13,
    height: 1.4,
    color: AppColors.muted,
  );
  static const nutritionStyle = TextStyle(
    fontSize: 13,
    color: AppColors.muted,
    fontWeight: FontWeight.w500,
  );
  static String nutritionLabel(AppLocalizations l, Recipe recipe) =>
      '${l.recipeNutrition(recipe.nutrition!.calories, recipe.nutrition!.proteinGrams, recipe.nutrition!.carbsGrams)} · ${l.perServingLabel}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final content = recipe.contentFor(
      Localizations.localeOf(context).languageCode,
    );
    return Material(
      color: const Color(0xFFFEFDF9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              fit: StackFit.expand,
              children: [
                InkWell(
                  onTap: onOpen,
                  child: RecipeImage(index: recipe.imageIndex),
                ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xF7FEFDF9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      child: Text(
                        recipe.slot.label(l10n),
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: IconButton.filledTonal(
                    tooltip: l10n.homeUseRecipe,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xF7FEFDF9),
                      foregroundColor: AppColors.olive,
                    ),
                    onPressed: onPlan,
                    icon: const Icon(Icons.bookmark_add_outlined, size: 21),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(content.title, style: titleStyle),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.recipeMinutes(recipe.minutes)}  ·  ${l10n.recipeServings(recipe.servings)}',
                    style: metaStyle,
                  ),
                  if (recipe.nutrition != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      nutritionLabel(l10n, recipe),
                      style: nutritionStyle,
                    ),
                  ],
                  const Spacer(),
                  const SizedBox(height: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.olive,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onPressed: onOpen,
                    child: Text(l10n.homeViewRecipe),
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
