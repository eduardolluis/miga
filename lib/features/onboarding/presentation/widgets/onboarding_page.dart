import 'package:flutter/material.dart';

import 'package:miga/features/onboarding/presentation/models/onboarding_page_data.dart';

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
