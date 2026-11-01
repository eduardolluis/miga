import 'package:flutter/material.dart';
import 'package:miga/core/ui/miga_skeleton.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';

/// Ingredient illustrations are bundled with Miga, so they work offline.
/// A stable enum-based asset path prevents a label/locale mismatch.
class IngredientImage extends StatelessWidget {
  const IngredientImage({super.key, required this.ingredient, this.size = 42});

  final RecipeIngredient ingredient;
  final double size;

  static String assetFor(RecipeIngredient ingredient) =>
      'assets/images/ingredients/${ingredient.name}.png';

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Image.asset(
          assetFor(ingredient),
          key: ValueKey('ingredient-icon-${ingredient.name}'),
          frameBuilder: skeletonImageFrame,
          fit: BoxFit.contain,
          semanticLabel: ingredient.label(
            Localizations.localeOf(context).languageCode,
          ),
          errorBuilder: (_, _, _) => const Icon(
            Icons.restaurant_outlined,
            size: 22,
            color: Color(0xFF526640),
          ),
        ),
      ),
    ),
  );
}
