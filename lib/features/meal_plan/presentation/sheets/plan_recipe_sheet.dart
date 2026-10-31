import 'package:flutter/material.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/meal_plan/presentation/meal_slot_presentation.dart';
import 'package:miga/l10n/app_localizations.dart';

Future<(DateTime, MealSlot, int)?> showPlanRecipe(
  BuildContext context, {
  required Recipe recipe,
  required List<DateTime> week,
  required DateTime selectedDate,
  required String? Function(DateTime, MealSlot) mealFor,
}) {
  var date = selectedDate;
  var slot = recipe.slot;
  var servings = recipe.servings;
  return showModalBottomSheet<(DateTime, MealSlot, int)>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, update) {
        final l = AppLocalizations.of(context)!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                recipe.contentFor(l.localeName).title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<DateTime>(
                initialValue: date,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.chooseDay),
                items: [
                  for (final day in week)
                    DropdownMenuItem(
                      value: day,
                      child: Text(
                        MaterialLocalizations.of(context).formatFullDate(day),
                      ),
                    ),
                ],
                onChanged: (value) => update(() => date = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MealSlot>(
                initialValue: slot,
                decoration: InputDecoration(labelText: l.mealActions),
                items: [
                  for (final value in MealSlot.values)
                    DropdownMenuItem(value: value, child: Text(value.label(l))),
                ],
                onChanged: (value) => update(() => slot = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: servings,
                decoration: InputDecoration(labelText: l.servingsLabel),
                items: [
                  for (var count = 1; count <= 24; count++)
                    DropdownMenuItem(value: count, child: Text('$count')),
                ],
                onChanged: (value) => update(() => servings = value!),
              ),
              if (mealFor(date, slot) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(l.overwriteWarning),
                ),
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('confirm-plan-recipe'),
                onPressed: () => Navigator.pop(context, (date, slot, servings)),
                child: Text(l.homeUseRecipe),
              ),
            ],
          ),
        );
      },
    ),
  );
}
