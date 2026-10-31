import 'package:flutter/material.dart';

import 'package:miga/app/navigation/app_tab.dart';
import 'package:miga/l10n/app_localizations.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedTab,
    required this.onSelected,
  });

  final AppTab selectedTab;
  final ValueChanged<AppTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return NavigationBar(
      height: 76,
      selectedIndex: selectedTab.index,
      onDestinationSelected: (index) => onSelected(AppTab.values[index]),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: l10n.homeNavHome,
        ),
        NavigationDestination(
          icon: const Icon(Icons.calendar_month_outlined),
          selectedIcon: const Icon(Icons.calendar_month_rounded),
          label: l10n.homeNavPlan,
        ),
        NavigationDestination(
          icon: const Icon(Icons.restaurant_menu_outlined),
          label: l10n.homeNavRecipes,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline_rounded),
          selectedIcon: const Icon(Icons.person_rounded),
          label: l10n.homeNavProfile,
        ),
      ],
    );
  }
}
