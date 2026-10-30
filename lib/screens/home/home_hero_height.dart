import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/home_details.dart';
import 'meal_slot.dart';

/// Both pages use the same height, including when text is enlarged.
double homeHeroHeight(
  BuildContext context, {
  required double width,
  required DateTime date,
  required String? meal,
  required WeeklyBudget? budget,
}) {
  final l10n = AppLocalizations.of(context)!;
  final defaults = DefaultTextStyle.of(context).style;
  final scaler = MediaQuery.textScalerOf(context);
  double height(
    String text,
    TextStyle style,
    double availableWidth, {
    int? lines,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: defaults.merge(style)),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      maxLines: lines,
    )..layout(maxWidth: availableWidth);
    final result = painter.height;
    painter.dispose();
    return result;
  }

  final inner = width - 40;
  const title = TextStyle(
    fontFamily: 'LiberationSerif',
    fontSize: 30,
    height: 1.05,
  );
  final chipHeight = MealSlot.values
      .map(
        (slot) =>
            height(
              slot.label(l10n),
              const TextStyle(fontSize: 12),
              double.infinity,
            ) +
            24,
      )
      .reduce(math.max);
  final mealHeight =
      40 +
      math.max(48, chipHeight) +
      height(
        '${l10n.homeTodayPlan} · ${MaterialLocalizations.of(context).formatShortDate(date)}',
        const TextStyle(fontSize: 12, letterSpacing: 0.6),
        inner,
      ) +
      8 +
      height(meal ?? l10n.homeEmptyHeroTitle, title, inner, lines: 3) +
      10 +
      (meal == null
          ? height(
              l10n.homeEmptyHeroDescription,
              const TextStyle(fontSize: 13, height: 1.4),
              inner,
            )
          : 0) +
      14 +
      math.max(
        48,
        height(
              meal == null ? l10n.homeAddMeal : l10n.homeEditMeal,
              Theme.of(context).textTheme.labelLarge!,
              inner - 28,
            ) +
            28,
      ) +
      math.max(
        40,
        height(l10n.homeRecipeIdea, const TextStyle(fontSize: 12), inner - 16) +
            16,
      );

  final budgetWidth = width - 48;
  final budgetContent = budget == null
      ? height(
              l10n.homeBudgetEmptyTitle,
              const TextStyle(
                fontFamily: 'LiberationSerif',
                fontSize: 31,
                height: 1.05,
              ),
              budgetWidth,
            ) +
            12 +
            height(
              l10n.homeBudgetEmptyDescription,
              const TextStyle(height: 1.5),
              budgetWidth,
            )
      : height(
              l10n.homeBudgetSpent,
              const TextStyle(fontSize: 12),
              budgetWidth,
            ) +
            8 +
            height(
              budget.format(budget.spent),
              const TextStyle(fontFamily: 'LiberationSerif', fontSize: 36),
              budgetWidth,
            ) +
            height(
              '/ ${budget.format(budget.limit)}',
              const TextStyle(fontSize: 18),
              budgetWidth,
            ) +
            20 +
            9 +
            12 +
            height(
              budget.spent > budget.limit
                  ? l10n.homeBudgetOver
                  : l10n.homeBudgetOnTrack,
              const TextStyle(fontSize: 13),
              budgetWidth,
            );
  final budgetHeight =
      48 +
      28 +
      14 +
      height(
        l10n.homeBudget,
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        budgetWidth,
      ) +
      budgetContent +
      20 +
      math.max(
        48,
        height(
              budget == null ? l10n.homeSetBudget : l10n.homeEditBudget,
              Theme.of(context).textTheme.labelLarge!,
              budgetWidth - 28,
            ) +
            28,
      );

  return math.max(350, math.max(mealHeight, budgetHeight) + 16);
}
