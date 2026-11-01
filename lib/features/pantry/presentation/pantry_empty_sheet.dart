import 'package:flutter/material.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/core/theme/app_theme.dart';
import 'package:miga/l10n/app_localizations.dart';

Future<bool?> showPantryEmptySheet(BuildContext context) =>
    showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      showDragHandle: true,
      builder: (context) {
        final l = AppLocalizations.of(context)!;
        return Theme(
          data: AppTheme.household(Theme.of(context)),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4EEDC),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.kitchen_outlined,
                        color: AppColors.olive,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l.pantryEmptyTitle,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 27,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.pantryEmptyMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const ValueKey('pantry-empty-add'),
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: Text(l.pantryAddIngredients),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l.cancelAction),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
