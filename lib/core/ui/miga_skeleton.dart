import 'package:flutter/material.dart';

/// A shared shimmer for a group of placeholders. Hidden tabs stop their ticker.
class MigaSkeleton extends StatefulWidget {
  const MigaSkeleton({super.key, required this.child});

  final Widget child;

  @override
  State<MigaSkeleton> createState() => _MigaSkeletonState();
}

class _MigaSkeletonState extends State<MigaSkeleton>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _animation.stop();
    } else if (!_animation.isAnimating) {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _animation,
          child: widget.child,
          builder: (context, child) => ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) =>
                const LinearGradient(
                  colors: [
                    Color(0xFFE5E5D9),
                    Color(0xFFF4F3EB),
                    Color(0xFFE5E5D9),
                  ],
                  stops: [0, .5, 1],
                ).createShader(
                  Rect.fromLTWH(
                    bounds.left + bounds.width * (_animation.value * 3 - 2),
                    bounds.top,
                    bounds.width * 2,
                    bounds.height,
                  ),
                ),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 16, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFE5E5D9),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Keeps the mounted content and its scroll/filter state during reloads.
class SkeletonContent extends StatelessWidget {
  const SkeletonContent({
    super.key,
    required this.loading,
    required this.skeleton,
    required this.child,
  });

  final bool loading;
  final Widget skeleton;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ExcludeSemantics(
        excluding: loading,
        child: IgnorePointer(
          ignoring: loading,
          child: AnimatedOpacity(
            opacity: loading ? 0 : 1,
            duration: loading || MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            child: child,
          ),
        ),
      ),
      if (loading) skeleton,
    ],
  );
}

/// Use as Image.frameBuilder so placeholders follow actual image decoding.
/// Cached images appear immediately; errors still use the image's errorBuilder.
Widget skeletonImageFrame(
  BuildContext context,
  Widget child,
  int? frame,
  bool wasSynchronouslyLoaded,
) {
  if (wasSynchronouslyLoaded) return child;
  return Stack(
    fit: StackFit.passthrough,
    children: [
      if (frame == null)
        const Positioned.fill(
          child: ExcludeSemantics(child: SkeletonBox(height: double.infinity)),
        ),
      AnimatedOpacity(
        opacity: frame == null ? 0 : 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
        child: child,
      ),
    ],
  );
}

class SkeletonRows extends StatelessWidget {
  const SkeletonRows({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) => MigaSkeleton(
    child: Column(
      children: [
        for (var i = 0; i < count; i++)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SkeletonBox(width: 44, height: 48, radius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FractionallySizedBox(
                        widthFactor: .78,
                        child: SkeletonBox(),
                      ),
                      SizedBox(height: 9),
                      FractionallySizedBox(
                        widthFactor: .5,
                        child: SkeletonBox(height: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class SkeletonRecipeCards extends StatelessWidget {
  const SkeletonRecipeCards({super.key});

  @override
  Widget build(BuildContext context) => const MigaSkeleton(
    child: Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: .88,
            child: SkeletonBox(height: double.infinity, radius: 18),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: AspectRatio(
            aspectRatio: .88,
            child: SkeletonBox(height: double.infinity, radius: 18),
          ),
        ),
      ],
    ),
  );
}
