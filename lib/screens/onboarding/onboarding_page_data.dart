import '../../l10n/app_localizations.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.imagePath,
  });

  final String title;
  final String description;
  final String imagePath;

  static List<OnboardingPageData> fromLocalizations(AppLocalizations l10n) {
    return [
      OnboardingPageData(
        title: l10n.welcomeTitle,
        description: l10n.welcomeDescription,
        imagePath: 'assets/images/onboarding/welcome.png',
      ),
      OnboardingPageData(
        title: l10n.planTitle,
        description: l10n.planDescription,
        imagePath: 'assets/images/onboarding/meal-planning.png',
      ),
      OnboardingPageData(
        title: l10n.shoppingTitle,
        description: l10n.shoppingDescription,
        imagePath: 'assets/images/onboarding/grocery-list.png',
      ),
      OnboardingPageData(
        title: l10n.storesTitle,
        description: l10n.storesDescription,
        imagePath: 'assets/images/onboarding/nearby-stores.png',
      ),
    ];
  }
}
