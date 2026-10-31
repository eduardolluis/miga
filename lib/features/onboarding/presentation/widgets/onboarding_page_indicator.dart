import 'package:flutter/material.dart';

import 'package:miga/l10n/app_localizations.dart';

class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    required this.onSelected,
  });

  final int pageCount;
  final int currentPage;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.white;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isSelected = currentPage == index;

        return Semantics(
          label: l10n.onboardingStep(index + 1, pageCount),
          selected: isSelected,
          button: true,
          child: InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(24),
            // Keep the touch target larger than the visible progress bar.
            child: SizedBox(
              width: 44,
              height: 48,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : primaryColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
