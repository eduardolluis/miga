import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/l10n/app_localizations.dart';

class ProPage extends StatelessWidget {
  const ProPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
        title: const Text('Miga Pro'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppColors.olive,
                  size: 36,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.proOfferTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'LiberationSerif',
                    fontSize: 36,
                    height: 1.1,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.proIntroduction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 28),
                _PlanSection(
                  title: l10n.proFreePlan,
                  description: l10n.proFreeDescription,
                  children: [
                    _Benefit(
                      icon: Icons.calendar_today_outlined,
                      title: l10n.proFreePlanning,
                    ),
                    _Benefit(
                      icon: Icons.restaurant_menu_rounded,
                      title: l10n.proFreeRecipes,
                    ),
                    _Benefit(
                      icon: Icons.shopping_bag_outlined,
                      title: l10n.proFreeShopping,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _PlanSection(
                  title: 'Miga Pro',
                  description: l10n.proInDevelopment,
                  highlighted: true,
                  children: [
                    _Benefit(
                      icon: Icons.auto_awesome_outlined,
                      title: l10n.proAutomaticPlans,
                      description: l10n.proAutomaticPlansDescription,
                    ),
                    _Benefit(
                      icon: Icons.kitchen_outlined,
                      title: l10n.proPantryPlans,
                      description: l10n.proPantryPlansDescription,
                    ),
                    _Benefit(
                      icon: Icons.people_outline_rounded,
                      title: l10n.proSharedLists,
                      description: l10n.proSharedListsDescription,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.proLaunchNote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.proKeepPlanning),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanSection extends StatelessWidget {
  const _PlanSection({
    required this.title,
    required this.description,
    required this.children,
    this.highlighted = false,
  });
  final String title;
  final String description;
  final List<Widget> children;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: highlighted ? const Color(0xFFEBEDDF) : const Color(0xFFFEFDF9),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: highlighted ? AppColors.olive : AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontFamily: 'LiberationSerif', fontSize: 26),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, this.description});
  final IconData icon;
  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.olive, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 5),
                Text(
                  description!,
                  style: const TextStyle(color: AppColors.muted, height: 1.5),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
