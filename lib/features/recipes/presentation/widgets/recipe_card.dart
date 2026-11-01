import 'package:flutter/material.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_image.dart';
import 'package:miga/features/recipes/presentation/widgets/favorite_heart_icon.dart';
import 'package:miga/l10n/app_localizations.dart';

/// Entire tile is the photograph: no card background or white text footer.
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.ingredientSummary,
    this.costLabel,
    this.favorite = false,
    this.onFavorite,
  });

  final Recipe recipe;
  final VoidCallback? onTap;
  final String? ingredientSummary;
  final String? costLabel;
  final bool favorite;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final title = recipe.contentFor(Localizations.localeOf(context).languageCode).title;
    return ClipRRect(
      key: ValueKey('recipe-card-${recipe.id}'),
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: const Color(0xFF4D5D3E),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RecipeImage(index: recipe.imageIndex),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, .48, 1],
                    colors: [Color(0x3F000000), Colors.transparent, Color(0xDD101B0E)],
                  ),
                ),
              ),
              if (costLabel != null)
                Positioned(
                  top: 9,
                  left: 9,
                  right: 44,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F3DD),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        costLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              if (onFavorite != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    key: ValueKey('recipe-favorite-${recipe.id}'),
                    onPressed: onFavorite,
                    tooltip: favorite ? l.favoriteRemove : l.favoriteAdd,
                    icon: FavoriteHeartIcon(favorite: favorite, size: 25),
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0x2C000000),
                      minimumSize: const Size(38, 38),
                    ),
                  ),
                ),
              Positioned(
                left: 11,
                right: 10,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.12,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(spacing: 9, runSpacing: 2, children: [
                      _Metadata(icon: Icons.schedule_rounded, label: l.recipeMinutes(recipe.minutes)),
                      _Metadata(icon: Icons.restaurant_outlined, label: '${recipe.servings}'),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Colors.white, size: 13),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 10.5)),
    ],
  );
}
