import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/l10n/app_localizations.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onProfile,
    required this.now,
    required this.name,
  });
  final VoidCallback onProfile;
  final DateTime now;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final greeting = switch (now.hour) {
      >= 5 && < 12 => l10n.homeGoodMorning,
      >= 12 && < 18 => l10n.homeGoodAfternoon,
      >= 18 && < 21 => l10n.homeGoodEvening,
      _ => l10n.homeGoodNight,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name == null ? '$greeting.' : '$greeting,\n$name.',
                style: const TextStyle(
                  fontFamily: 'LiberationSerif',
                  color: AppColors.ink,
                  fontSize: 32,
                  height: 1.06,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                MaterialLocalizations.of(context).formatFullDate(now),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox.square(
          key: const ValueKey('home-profile-avatar'),
          dimension: 52,
          child: Material(
            color: const Color(0xFFE8EBDF),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              tooltip: l10n.homeAccount,
              onPressed: onProfile,
              padding: EdgeInsets.zero,
              icon: name == null
                  ? const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.olive,
                    )
                  : Text(
                      name!.characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.olive,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
