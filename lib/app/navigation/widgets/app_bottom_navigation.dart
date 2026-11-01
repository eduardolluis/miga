import 'package:flutter/material.dart';

import 'package:miga/app/navigation/app_tab.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/core/ui/miga_ui_copy.dart';
import 'package:miga/l10n/app_localizations.dart';

/// Minimal five-tab bottom bar matching the Home/Recipes reference.
/// All tabs use the existing AppTab routing and retain accessibility labels.
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
    final l = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.line, width: .8)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedTab.index,
        onTap: (index) => onSelected(AppTab.values[index]),
        backgroundColor: AppColors.cream,
        elevation: 0,
        selectedItemColor: AppColors.olive,
        unselectedItemColor: AppColors.muted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        iconSize: 25,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home_rounded),
            label: l.homeNavHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.restaurant_menu_outlined),
            activeIcon: const Icon(Icons.restaurant_menu_rounded),
            label: l.homeNavRecipes,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_month_outlined),
            activeIcon: const Icon(Icons.calendar_month_rounded),
            label: l.homeNavPlan,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart_outlined),
            activeIcon: const Icon(Icons.shopping_cart_rounded),
            label: MigaUiCopy.shopping(context),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline_rounded),
            activeIcon: const Icon(Icons.person_rounded),
            label: l.homeNavProfile,
          ),
        ],
      ),
    );
  }
}
