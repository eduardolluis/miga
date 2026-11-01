import 'package:flutter/material.dart';
import 'package:miga/core/ui/miga_skeleton.dart';

import 'package:miga/features/onboarding/presentation/models/onboarding_page_data.dart';

class OnboardingBackground extends StatelessWidget {
  const OnboardingBackground({super.key, required this.page});

  final OnboardingPageData page;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          page.imagePath,
          frameBuilder: skeletonImageFrame,
          fit: BoxFit.cover,
          alignment: page.imageAlignment,
          excludeFromSemantics: true,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x990E1710),
                Color(0x330E1710),
                Color(0x990E1710),
                Color(0xF00E1710),
              ],
              stops: [0, 0.35, 0.65, 1],
            ),
          ),
        ),
      ],
    );
  }
}
