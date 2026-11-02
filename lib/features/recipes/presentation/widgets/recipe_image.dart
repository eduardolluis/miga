import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:miga/core/ui/miga_skeleton.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/recipes/domain/recipe_photo.dart';

/// Recipe images come ONLY from published remote Storage URLs.
/// UI branding/onboarding assets remain independent of the recipe catalog.
class RecipeImage extends StatefulWidget {
  const RecipeImage({
    super.key,
    required this.photo,
    this.fit = BoxFit.cover,
    this.useThumbnail = false,
  });
  final RecipePhoto photo;
  final BoxFit fit;
  final bool useThumbnail;

  static ImageProvider providerFor(
    RecipePhoto photo, {
    bool thumbnail = false,
  }) {
    final path = thumbnail ? photo.cardPath : photo.path;
    if (Uri.tryParse(path)?.scheme != 'https') {
      throw ArgumentError.value(path, 'photo', 'Expected HTTPS photo');
    }
    // The iOS disk cache depends on path_provider_foundation and the
    // objective_c native bridge. Its broken native-assets initialization can
    // leave every recipe image permanently on the skeleton. Use Flutter's
    // in-memory image cache on iOS instead; keep disk caching on Android.
    // This does not hide missing files in Supabase Storage: 404s still show
    // the explicit retry state below.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return NetworkImage(path);
    }
    return CachedNetworkImageProvider(path);
  }

  @override
  State<RecipeImage> createState() => _RecipeImageState();
}

class _RecipeImageState extends State<RecipeImage> {
  int _attempt = 0;

  @override
  void didUpdateWidget(covariant RecipeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo.path != widget.photo.path ||
        oldWidget.photo.cardPath != widget.photo.cardPath ||
        oldWidget.useThumbnail != widget.useThumbnail) {
      _attempt = 0;
    }
  }

  void _retry() {
    if (!widget.photo.isRemote) return;
    final provider = RecipeImage.providerFor(
      widget.photo,
      thumbnail: widget.useThumbnail,
    );
    provider.evict();
    setState(() => _attempt++);
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;
    if (!photo.isRemote) return _failure(context);
    final path = widget.useThumbnail ? photo.cardPath : photo.path;
    final sourceWidth = widget.useThumbnail ? photo.cardWidth : photo.width;
    final sourceHeight = widget.useThumbnail ? photo.cardHeight : photo.height;
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : sourceWidth.toDouble();
          final height = constraints.hasBoundedHeight
              ? constraints.maxHeight
              : sourceHeight.toDouble();
          final scale = widget.fit == BoxFit.cover
              ? math.max(width / sourceWidth, height / sourceHeight)
              : math.min(width / sourceWidth, height / sourceHeight);
          final cacheWidth =
              (sourceWidth * scale * MediaQuery.devicePixelRatioOf(context))
                  .ceil()
                  .clamp(1, sourceWidth);
          return Image(
            key: ValueKey('${photo.path}#$_attempt'),
            image: ResizeImage(
              RecipeImage.providerFor(photo, thumbnail: widget.useThumbnail),
              width: cacheWidth,
            ),
            frameBuilder: skeletonImageFrame,
            fit: widget.fit,
            width: double.infinity,
            height: double.infinity,
            // Bilinear sampling is sufficient for thumbnails and avoids the
            // more expensive high-quality sampling during grid scrolling.
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
            errorBuilder: (_, error, stack) {
              assert(() {
                debugPrint('Miga recipe photo unavailable: $path ($error)');
                return true;
              }());
              return _failure(context);
            },
          );
        },
      ),
    );
  }

  Widget _failure(BuildContext context) => ColoredBox(
    color: const Color(0xFFE7EAD9),
    child: Center(
      child: IconButton(
        tooltip: Localizations.localeOf(context).languageCode == 'es'
            ? 'Reintentar cargar imagen'
            : 'Retry photo',
        onPressed: widget.photo.isRemote ? _retry : null,
        icon: const Icon(Icons.refresh_rounded, color: AppColors.olive),
      ),
    ),
  );
}
