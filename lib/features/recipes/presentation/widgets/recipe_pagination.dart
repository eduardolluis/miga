import 'package:flutter/material.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/l10n/app_localizations.dart';

class RecipePagination extends StatelessWidget {
  const RecipePagination({
    super.key,
    required this.page,
    required this.pages,
    required this.onPrevious,
    required this.onNext,
  });
  final int page, pages;
  final VoidCallback? onPrevious, onNext;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final position = Text(
      l.recipePagePosition(page + 1, pages),
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(liveRegion: true, child: position),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final previous = OutlinedButton.icon(
              key: const ValueKey('recipes-previous-bottom'),
              onPressed: onPrevious,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 52),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                foregroundColor: AppColors.olive,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.chevron_left_rounded),
              label: Text(l.recipePreviousPage),
            );
            final next = FilledButton.icon(
              key: const ValueKey('recipes-next-bottom'),
              onPressed: onNext,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 52),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: AppColors.olive,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.chevron_right_rounded),
              iconAlignment: IconAlignment.end,
              label: Text(l.recipeNextPage),
            );
            if (constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(14) > 20) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [next, const SizedBox(height: 8), previous],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: previous),
                  const SizedBox(width: 12),
                  Expanded(child: next),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
