import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/meal_plan/presentation/meal_slot_presentation.dart';
import 'package:miga/l10n/app_localizations.dart';

class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.slot,
    required this.meal,
    required this.onTap,
    this.onChooseRecipe,
    this.onAction,
  });

  final MealSlot slot;
  final String? meal;
  final VoidCallback? onTap;
  final VoidCallback? onChooseRecipe;
  final ValueChanged<String>? onAction;

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
                          fontSize: 13,
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
                if (onChooseRecipe != null)
                  IconButton(
                    onPressed: onChooseRecipe,
                    tooltip: l10n.chooseRecipe,
                    icon: const Icon(
                      Icons.restaurant_menu,
                      color: AppColors.olive,
                    ),
                  ),
                if (meal != null && onAction != null)
                  PopupMenuButton<String>(
                    tooltip: l10n.mealActions,
                    onSelected: onAction,
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'move', child: Text(l10n.moveMeal)),
                      PopupMenuItem(value: 'copy', child: Text(l10n.copyMeal)),
                      PopupMenuItem(
                        value: 'repeat',
                        child: Text(l10n.repeatMeal),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.homeRemoveMeal),
                      ),
                    ],
                  )
                else
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
