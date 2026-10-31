import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/l10n/app_localizations.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.pendingItems,
    required this.onGroceries,
    required this.onStores,
  });
  final int pendingItems;
  final VoidCallback? onGroceries;
  final VoidCallback? onStores;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cards = [
      _ActionCard(
        icon: Icons.shopping_basket_outlined,
        title: l10n.homeGroceryList,
        subtitle: pendingItems == 0
            ? l10n.homeGroceryEmpty
            : l10n.homeGroceryCount(pendingItems),
        onTap: onGroceries,
      ),
      _ActionCard(
        icon: Icons.storefront_outlined,
        title: l10n.homeStores,
        subtitle: l10n.homeOpenMaps,
        onTap: onStores,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(14) > 20) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [cards[0], const SizedBox(height: 16), cards[1]],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ],
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFEFDF9),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: AppColors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFEBEEE3),
              foregroundColor: AppColors.olive,
              child: Icon(icon, size: 21),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'LiberationSerif',
                fontSize: 21,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
