import 'package:flutter/material.dart';

import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/l10n/app_localizations.dart';

extension MealSlotPresentation on MealSlot {
  IconData get icon => switch (this) {
    MealSlot.breakfast => Icons.wb_twilight_rounded,
    MealSlot.lunch => Icons.light_mode_outlined,
    MealSlot.dinner => Icons.nightlight_outlined,
  };

  String label(AppLocalizations l10n) => switch (this) {
    MealSlot.breakfast => l10n.homeBreakfast,
    MealSlot.lunch => l10n.homeLunch,
    MealSlot.dinner => l10n.homeDinner,
  };
}
