import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/recipes/data/recipe_photo_catalog.dart';

class RecipeImage extends StatelessWidget {
  const RecipeImage({super.key, required this.index, this.fit = BoxFit.cover});
  final int index;
  final BoxFit fit;

  static String? localAssetFor(int imageIndex) =>
      RecipePhotoCatalog.images[imageIndex]?.asset;
  static double? aspectRatioFor(int imageIndex) =>
      RecipePhotoCatalog.images[imageIndex]?.aspectRatio;
  static ImageProvider? providerFor(int imageIndex) {
    final asset = localAssetFor(imageIndex);
    return asset == null ? null : AssetImage(asset);
  }

  @override
  Widget build(BuildContext context) {
    final photo = RecipePhotoCatalog.images[index];
    if (photo == null) return _fallback();
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : photo.width.toDouble();
          final height = constraints.hasBoundedHeight
              ? constraints.maxHeight
              : photo.height.toDouble();
          final scale = fit == BoxFit.cover
              ? math.max(width / photo.width, height / photo.height)
              : math.min(width / photo.width, height / photo.height);
          // Cover also accounts for height so tall cards stay sharp on Retina screens.
          final cacheWidth =
              (photo.width * scale * MediaQuery.devicePixelRatioOf(context))
                  .ceil()
                  .clamp(1, photo.width);
          return Image.asset(
            photo.asset,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            cacheWidth: cacheWidth,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stack) => _fallback(),
          );
        },
      ),
    );
  }

  static Widget _fallback() => const ColoredBox(
    color: Color(0xFFE7EAD9),
    child: Center(child: Icon(Icons.restaurant, color: AppColors.olive)),
  );
}
