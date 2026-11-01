import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_image.dart';

/// Source dimensions reserve the correct space before the local photo decodes.
class RecipeDetailPhoto extends StatelessWidget {
  const RecipeDetailPhoto({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final maxHeight = math.max(
        140.0,
        math.min(380.0, MediaQuery.sizeOf(context).height * .48),
      );
      final naturalHeight =
          constraints.maxWidth / (RecipeImage.aspectRatioFor(index) ?? 4 / 3);
      return AnimatedSize(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: SizedBox(
          key: const ValueKey('recipe-detail-photo-frame'),
          width: double.infinity,
          height: naturalHeight.clamp(140.0, maxHeight),
          child: RecipeImage(index: index, fit: BoxFit.contain),
        ),
      );
    },
  );
}
