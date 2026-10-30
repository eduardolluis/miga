import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

class HomeRecipeCard extends StatelessWidget {
  const HomeRecipeCard({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              'assets/images/home/lemon-salmon.png',
              height: 180,
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.3),
              excludeFromSemantics: true,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeRecipeMeta,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.homeRecipeTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.homeRecipeSubtitle,
                    style: const TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.homeViewRecipe,
                          style: const TextStyle(
                            color: AppColors.olive,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.olive,
                        size: 19,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showHomeRecipe(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.cream,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Text(
              l10n.homeRecipeTitle,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.homeRecipeMeta,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.homeIngredients,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.homeRecipeIngredients,
              style: const TextStyle(fontSize: 16, height: 1.8),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.homePreparation,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.homeRecipeSteps,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 28),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.olive,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.homeUseRecipe),
            ),
          ],
        ),
      );
    },
  );
}
