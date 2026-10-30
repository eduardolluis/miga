import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/home_details.dart';
import '../../theme/app_colors.dart';

class HomeBudgetCard extends StatelessWidget {
  const HomeBudgetCard({super.key, required this.budget, required this.onEdit});

  final WeeklyBudget? budget;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = budget;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EBDF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.olive,
            size: 28,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.homeBudget,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.olive,
            ),
          ),
          const Spacer(),
          if (value == null) ...[
            Text(
              l10n.homeBudgetEmptyTitle,
              style: const TextStyle(
                fontFamily: 'LiberationSerif',
                fontSize: 31,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.homeBudgetEmptyDescription,
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
          ] else ...[
            Text(
              l10n.homeBudgetSpent,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 8,
              children: [
                Text(
                  value.format(value.spent),
                  style: const TextStyle(
                    fontFamily: 'LiberationSerif',
                    fontSize: 36,
                  ),
                ),
                Text(
                  '/ ${value.format(value.limit)}',
                  style: const TextStyle(fontSize: 18, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: (value.spent / value.limit).clamp(0.0, 1.0),
              minHeight: 9,
              borderRadius: BorderRadius.circular(8),
              color: value.spent > value.limit
                  ? const Color(0xFFA34F36)
                  : AppColors.olive,
              backgroundColor: const Color(0xFFD1D8C4),
            ),
            const SizedBox(height: 12),
            Text(
              value.spent > value.limit
                  ? l10n.homeBudgetOver
                  : l10n.homeBudgetOnTrack,
              style: const TextStyle(color: AppColors.ink, fontSize: 13),
            ),
          ],
          const Spacer(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.olive,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(14),
              ),
              onPressed: onEdit,
              child: Text(
                value == null ? l10n.homeSetBudget : l10n.homeEditBudget,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
