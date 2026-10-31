import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Each recipe uses its own photo from the bundled 3×3 image atlas.
class RecipeImage extends StatelessWidget {
  const RecipeImage({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final tile = math.max(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            Positioned(
              left: -(index % 3 * tile + (tile - constraints.maxWidth) / 2),
              top: -(index ~/ 3 * tile + (tile - constraints.maxHeight) / 2),
              width: tile * 3,
              height: tile * 3,
              child: Image.asset(
                'assets/images/home/recipes-casual.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                excludeFromSemantics: true,
              ),
            ),
          ],
        );
      },
    ),
  );
}
