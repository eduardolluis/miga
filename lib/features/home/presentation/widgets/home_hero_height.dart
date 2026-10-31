import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:miga/features/home/presentation/widgets/meal_hero_card.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/l10n/app_localizations.dart';

/// The photos and panels stay aligned while translated or enlarged text grows.
double homeHeroHeight(
  BuildContext context,
  double width,
  List<Recipe> recipes,
) {
  final l10n = AppLocalizations.of(context)!;
  final scaler = MediaQuery.textScalerOf(context);
  double measure(String text, TextStyle style, double available) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: scaler,
    )..layout(maxWidth: math.max(1, available));
    final height = painter.height;
    painter.dispose();
    return height;
  }

  final metaHeight = recipes
      .map(
        (recipe) => measure(
          '${l10n.recipeMinutes(recipe.minutes)}  ·  ${l10n.recipeServings(recipe.servings)}',
          MealHeroCard.metaStyle,
          width - 40,
        ),
      )
      .reduce(math.max);
  final buttonHeight = math.max(
    52.0,
    measure(
          l10n.homeViewRecipe,
          Theme.of(context).textTheme.labelLarge!,
          width - 72,
        ) +
        28,
  );
  final titleHeight = recipes
      .map(
        (recipe) => measure(
          recipe.contentFor(l10n.localeName).title,
          MealHeroCard.titleStyle,
          width - 36,
        ),
      )
      .reduce(math.max);
  return 190 + 36 + titleHeight + 8 + metaHeight + 14 + buttonHeight + 4;
}
