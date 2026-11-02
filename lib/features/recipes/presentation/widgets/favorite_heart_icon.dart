import 'package:flutter/material.dart';

/// A small, gentle transition that does not resize the card or reflow a grid.
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
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: size,
      child: AnimatedSwitcher(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 260),
        reverseDuration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 210),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.center,
          children: [...previous, if (current != null) current],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.86, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: Icon(
          favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(favorite),
          color: favorite ? const Color(0xFFE53935) : inactiveColor,
          size: size,
        ),
      ),
    );
  }
}
