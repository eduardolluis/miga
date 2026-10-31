import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_image.dart';
import 'package:miga/l10n/app_localizations.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.ingredientSummary,
  });
  final Recipe recipe;
  final VoidCallback? onTap;
  final String? ingredientSummary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final content = recipe.contentFor(
      Localizations.localeOf(context).languageCode,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: const Color(0xFFFEFDF9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              SizedBox(
                width: 108,
                height: 130,
                child: RecipeImage(index: recipe.imageIndex),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.title,
                        style: const TextStyle(
                          fontFamily: 'LiberationSerif',
                          fontSize: 21,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.recipeMinutes(recipe.minutes),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                      if (ingredientSummary != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          ingredientSummary!,
                          style: const TextStyle(
                            color: AppColors.olive,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ] else if (recipe.nutrition != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${recipe.nutrition!.calories} kcal · ${recipe.nutrition!.proteinGrams}g prot',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 14),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.olive,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
