import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_image.dart';
import 'package:miga/l10n/app_localizations.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe, required this.onTap});
  final Recipe recipe;
  final VoidCallback? onTap;

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
