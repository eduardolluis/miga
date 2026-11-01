import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:miga/core/ui/miga_skeleton.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/recipes/domain/recipe_photo.dart';

class RecipeImage extends StatelessWidget {
  const RecipeImage({super.key, required this.photo, this.fit = BoxFit.cover});
  final RecipePhoto photo;
  final BoxFit fit;
  static ImageProvider providerFor(RecipePhoto photo) => photo.isRemote
      ? CachedNetworkImageProvider(photo.path)
      : AssetImage(photo.path);
  @override
  Widget build(BuildContext context) => ClipRect(
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
        final cacheWidth =
            (photo.width * scale * MediaQuery.devicePixelRatioOf(context))
                .ceil()
                .clamp(1, photo.width);
        return Image(
          key: ValueKey(photo.path),
          image: ResizeImage(providerFor(photo), width: cacheWidth),
          frameBuilder: skeletonImageFrame,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          filterQuality: FilterQuality.high,
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: Color(0xFFE7EAD9),
            child: Center(
              child: Icon(Icons.restaurant, color: AppColors.olive),
            ),
          ),
        );
      },
    ),
  );
}
