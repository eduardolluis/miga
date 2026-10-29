import 'package:flutter/material.dart';

import 'onboarding_page_data.dart';

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

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.page});

  final OnboardingPageData page;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  page.title,
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                    shadows: const [
                      Shadow(color: Colors.black38, blurRadius: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  page.description,
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
