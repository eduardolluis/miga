import 'package:flutter/material.dart';

/// Instant, accessible favorite feedback shared by Home, Recipes and details.
/// The filled state is always red; the outline respects the card background.
class FavoriteHeartIcon extends StatelessWidget {
  const FavoriteHeartIcon({
    super.key,
    required this.favorite,
    this.inactiveColor = Colors.white,
    this.size = 22,
  });

  final bool favorite;
  final Color inactiveColor;
  final double size;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 190),
    reverseDuration: const Duration(milliseconds: 140),
    switchInCurve: Curves.easeOutBack,
    switchOutCurve: Curves.easeIn,
    transitionBuilder: (child, animation) =>
        ScaleTransition(scale: animation, child: child),
    child: Icon(
      favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      key: ValueKey(favorite),
      color: favorite ? const Color(0xFFE53935) : inactiveColor,
      size: size,
    ),
  );
}
