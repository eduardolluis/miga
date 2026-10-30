import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import 'meal_slot.dart';

class HomeMealCard extends StatelessWidget {
  const HomeMealCard({
    super.key,
    required this.slot,
    required this.meal,
    required this.onTap,
  });

  final MealSlot slot;
  final String? meal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('home-meal-${slot.name}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: CircleAvatar(
                    backgroundColor: AppColors.cream,
                    foregroundColor: AppColors.olive,
                    child: Icon(slot.icon, size: 21),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slot.label(l10n),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meal ?? l10n.homeEmptyMeal,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: meal == null
                              ? FontWeight.w400
                              : FontWeight.w600,
                          color: meal == null ? AppColors.muted : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  meal == null ? Icons.add_rounded : Icons.edit_outlined,
                  color: AppColors.olive,
                  size: 21,
                  semanticLabel: meal == null
                      ? l10n.homeAddMeal
                      : l10n.homeEditMeal,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
