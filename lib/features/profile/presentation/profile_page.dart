import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/l10n/app_localizations.dart';
import 'package:miga/features/pro/presentation/widgets/pro_offer_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.name,
    required this.email,
    required this.onBudget,
    required this.onSignOut,
    required this.signingOut,
    required this.onPro,
    this.onPreferences,
    this.onPantry,
    this.onPrices,
    this.onSpending,
    this.onPrivacy,
    this.onDeleteAccount,
    this.onSync,
    this.syncLabel,
    this.onSharedList,
    this.onSavings,
    this.subscriptionActive = false,
  });

  final String? name;
  final String? email;
  final VoidCallback? onBudget;
  final VoidCallback? onSignOut;
  final bool signingOut;
  final VoidCallback onPro;
  final VoidCallback? onPreferences,
      onPantry,
      onPrices,
      onSpending,
      onPrivacy,
      onDeleteAccount,
      onSync,
      onSharedList;
  final String? syncLabel;
  final VoidCallback? onSavings;
  final bool subscriptionActive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          l10n.homeProfileTitle,
          style: const TextStyle(fontFamily: 'Georgia', fontSize: 32),
        ),
        const SizedBox(height: 32),
        const Align(
          alignment: Alignment.centerLeft,
          child: CircleAvatar(
            radius: 32,
            backgroundColor: Color(0xFFE8EBDF),
            child: Icon(Icons.person_outline, color: AppColors.olive, size: 32),
          ),
        ),
        const SizedBox(height: 18),
        if (name != null)
          Text(
            name!,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        if (email != null) ...[
          const SizedBox(height: 8),
          Text(
            email!,
            style: const TextStyle(color: AppColors.muted, fontSize: 16),
          ),
        ],
        const SizedBox(height: 28),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_balance_wallet_outlined),
          title: Text(l10n.homeBudget),
          trailing: const Icon(Icons.chevron_right),
          onTap: onBudget,
        ),
        const Divider(color: AppColors.line),
        for (final action in [
          (Icons.settings_outlined, l10n.preferencesTitle, onPreferences),
          (Icons.kitchen_outlined, l10n.pantryTitle, onPantry),
          (Icons.price_change_outlined, l10n.priceSettingsTitle, onPrices),
          (Icons.insights_outlined, l10n.spendingTitle, onSpending),
          (Icons.savings_outlined, l10n.substitutionsTitle, onSavings),
          (Icons.people_outline, l10n.sharedListTitle, onSharedList),
          (Icons.sync, syncLabel ?? l10n.syncTitle, onSync),
          (Icons.privacy_tip_outlined, l10n.privacyTitle, onPrivacy),
        ])
          if (action.$3 != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(action.$1),
              title: Text(action.$2),
              trailing: const Icon(Icons.chevron_right),
              onTap: action.$3,
            ),
        if (onDeleteAccount != null)
          TextButton.icon(
            onPressed: onDeleteAccount,
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.deleteAccount),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text(
            l10n.homeStorageNotice,
            style: const TextStyle(color: AppColors.muted, height: 1.5),
          ),
        ),
        if (onSignOut != null)
          OutlinedButton.icon(
            onPressed: signingOut ? null : onSignOut,
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: Text(l10n.signOut),
          ),
        if (signingOut) const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 24),
        Text(
          subscriptionActive ? 'Miga Pro' : l10n.proFreePlan,
          style: const TextStyle(
            color: AppColors.olive,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ProOfferCard(onOpen: onPro),
      ],
    );
  }
}
