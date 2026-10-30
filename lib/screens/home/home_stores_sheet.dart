import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

Future<bool?> showStoresEmptyState(BuildContext context) =>
    showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.cream,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.storefront_outlined,
                color: AppColors.olive,
                size: 48,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.homeStoresEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'LiberationSerif',
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.homeStoresDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.6),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.homeGroceryList),
              ),
            ],
          ),
        );
      },
    );
