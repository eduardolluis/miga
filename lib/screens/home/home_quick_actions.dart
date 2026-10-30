import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

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
        title: l10n.homeGroceryList,
        subtitle: pendingItems == 0
            ? l10n.homeGroceryEmpty
            : l10n.homeGroceryCount(pendingItems),
        image: 'assets/images/onboarding/grocery-list.png',
        onTap: onGroceries,
      ),
      _ActionCard(
        title: l10n.homeStores,
        subtitle: l10n.homeStoresSubtitle,
        image: 'assets/images/onboarding/nearby-stores.png',
        onTap: onStores,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(14) > 20) {
          return Column(
            children: [cards[0], const SizedBox(height: 14), cards[1]],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 14),
            Expanded(child: cards[1]),
          ],
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String image;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFCFAF4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            image,
            height: 100,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'LiberationSerif',
                    fontSize: 20,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.olive,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
