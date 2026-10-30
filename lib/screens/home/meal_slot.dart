import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

enum MealSlot {
  breakfast(Icons.wb_twilight_rounded),
  lunch(Icons.light_mode_outlined),
  dinner(Icons.nightlight_outlined);

  const MealSlot(this.icon);

  final IconData icon;

  String label(AppLocalizations l10n) => switch (this) {
    breakfast => l10n.homeBreakfast,
    lunch => l10n.homeLunch,
    dinner => l10n.homeDinner,
  };

  String keyFor(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month-$day:$name';
  }
}
