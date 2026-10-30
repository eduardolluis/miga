import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.onProfile});

  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'miga',
                style: TextStyle(
                  fontFamily: 'LiberationSerif',
                  fontSize: 36,
                  letterSpacing: -1.5,
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.homeAccount,
              onPressed: onProfile,
              icon: const CircleAvatar(
                backgroundColor: Color(0xFFE8EBDF),
                foregroundColor: AppColors.olive,
                child: Icon(Icons.person_outline_rounded, size: 23),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          l10n.homeGreeting,
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.homeTitle,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: 'LiberationSerif',
            fontSize: 29,
            letterSpacing: -0.6,
            height: 1.12,
          ),
        ),
      ],
    );
  }
}
