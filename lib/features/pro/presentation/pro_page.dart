import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/l10n/app_localizations.dart';
import 'package:miga/features/pro/application/store_subscription_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class ProPage extends StatelessWidget {
  const ProPage({
    super.key,
    this.purchases,
    this.onAutoPlan,
    this.onPantry,
    this.onSpending,
  });
  final StoreSubscriptionService? purchases;
  final VoidCallback? onAutoPlan, onPantry, onSpending;

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
                    _Benefit(
                      icon: Icons.account_balance_wallet_outlined,
                      title: l10n.localeName.startsWith('es')
                          ? 'Presupuesto semanal y costos estimados'
                          : 'Weekly budget and estimated meal costs',
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
                      icon: Icons.recommend_outlined,
                      title: l10n.localeName.startsWith('es')
                          ? 'Recomendaciones personalizadas'
                          : 'Personalized recommendations',
                      description: l10n.localeName.startsWith('es')
                          ? 'Sugerencias adaptadas a tus gustos y presupuesto familiar.'
                          : 'Suggestions tailored to your tastes and family budget.',
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
                    _Benefit(
                      icon: Icons.insights_outlined,
                      title: l10n.localeName.startsWith('es')
                          ? 'Análisis y optimización de gastos'
                          : 'Spending analysis & budget optimization',
                      description: l10n.localeName.startsWith('es')
                          ? 'Sustituciones inteligentes para ahorrar sin perder calidad.'
                          : 'Smart substitutions to save without losing quality.',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.proToolsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(l10n.proToolsNote),
                if (onAutoPlan != null)
                  TextButton.icon(
                    onPressed: onAutoPlan,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(l10n.autoPlanTitle),
                  ),
                if (onPantry != null)
                  TextButton.icon(
                    onPressed: onPantry,
                    icon: const Icon(Icons.kitchen_outlined),
                    label: Text(l10n.pantryTitle),
                  ),
                if (onSpending != null)
                  TextButton.icon(
                    onPressed: onSpending,
                    icon: const Icon(Icons.insights),
                    label: Text(l10n.spendingTitle),
                  ),
                if (purchases != null)
                  ListenableBuilder(
                    listenable: purchases!,
                    builder: (context, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (purchases!.busy) const LinearProgressIndicator(),
                        if (purchases!.active)
                          Text(
                            '${l10n.subscriptionActive} · ${MaterialLocalizations.of(context).formatShortDate(purchases!.expiresAt!)}',
                          ),
                        if (purchases!.available &&
                            purchases!.products.isNotEmpty)
                          for (final product in purchases!.products)
                            FilledButton(
                              onPressed: purchases!.busy
                                  ? null
                                  : () => purchases!.buy(product),
                              child: Text(
                                '${product.title} · ${product.price}',
                              ),
                            )
                        else
                          Text(l10n.subscriptionUnavailable),
                        if (purchases!.failed) Text(l10n.homeSaveError),
                        OutlinedButton(
                          onPressed: purchases!.available && !purchases!.busy
                              ? purchases!.restore
                              : null,
                          child: Text(l10n.restorePurchases),
                        ),
                        TextButton(
                          onPressed: () async {
                            final url =
                                defaultTargetPlatform == TargetPlatform.iOS
                                ? 'https://apps.apple.com/account/subscriptions'
                                : 'https://play.google.com/store/account/subscriptions';
                            if (!await launchUrl(
                                  Uri.parse(url),
                                  mode: LaunchMode.externalApplication,
                                ) &&
                                context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.homeSaveError)),
                              );
                            }
                          },
                          child: Text(l10n.manageSubscription),
                        ),
                      ],
                    ),
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
