import 'package:flutter/painting.dart';

import '../../l10n/app_localizations.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.imagePath,
    this.imageAlignment = Alignment.center,
  });

  final String title;
  final String description;
  final String imagePath;
  final Alignment imageAlignment;

  static List<OnboardingPageData> fromLocalizations(AppLocalizations l10n) {
    return [
      OnboardingPageData(
        title: l10n.welcomeTitle,
        description: l10n.welcomeDescription,
        imagePath: 'assets/images/onboarding/welcome.png',
        imageAlignment: const Alignment(-0.1, 0.35),
      ),
      OnboardingPageData(
        title: l10n.planTitle,
        description: l10n.planDescription,
        imagePath: 'assets/images/onboarding/meal-planning.png',
        imageAlignment: const Alignment(-0.4, 0.3),
      ),
      OnboardingPageData(
        title: l10n.shoppingTitle,
        description: l10n.shoppingDescription,
        imagePath: 'assets/images/onboarding/grocery-list.png',
        imageAlignment: const Alignment(0.25, 0.2),
      ),
      OnboardingPageData(
        title: l10n.storesTitle,
        description: l10n.storesDescription,
        imagePath: 'assets/images/onboarding/nearby-stores.png',
        imageAlignment: const Alignment(0.3, 0),
      ),
    ];
  }
}
