import 'package:flutter/material.dart';
import 'package:miga/core/ui/miga_skeleton.dart';
import 'package:miga/features/home/application/home_controller.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/meal_plan/presentation/meal_slot_presentation.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/l10n/app_localizations.dart';

class SavingsPage extends StatelessWidget {
  const SavingsPage({
    super.key,
    required this.controller,
    required this.onReplace,
  });
  final HomeController controller;
  final Future<void> Function(DateTime, MealSlot, Recipe) onReplace;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(AppLocalizations.of(context)!.substitutionsTitle),
    ),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final l = AppLocalizations.of(context)!;
          final money = WeeklyBudget(
            limit: 0,
            spent: 0,
            currency: controller.costCurrency,
          );
          final alternatives = [
            for (final date in controller.week)
              for (final slot in MealSlot.values)
                if (controller.recipeFor(date, slot) case final Recipe original)
                  for (final candidate in controller.cheaperAlternatives(
                    original,
                  ))
                    (date, slot, original, candidate),
          ];
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(l.substitutionsNote),
              const SizedBox(height: 20),
              if (alternatives.isEmpty)
                if (controller.pricing || controller.loading)
                  const SkeletonRows()
                else
                  Text(l.savingsEmpty)
              else if (controller.pricing)
                const LinearProgressIndicator(),
              for (final (date, slot, original, candidate) in alternatives)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${MaterialLocalizations.of(context).formatShortMonthDay(date)} · ${slot.label(l)}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${original.contentFor(l.localeName).title} → ${candidate.contentFor(l.localeName).title}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${l.recipeServings(candidate.servings)} · ${money.format(controller.costFor(original).subtotalCents / 100)} → ${money.format(controller.costFor(candidate).subtotalCents / 100)}',
                        ),
                        TextButton(
                          onPressed: controller.canEdit
                              ? () async {
                                  final accepted = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(l.confirmReplace),
                                      content: Text(
                                        '${candidate.contentFor(l.localeName).title}\n${candidate.contentFor(l.localeName).ingredients.join('\n')}',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text(l.cancelAction),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text(l.replaceAction),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (accepted == true && context.mounted) {
                                    await onReplace(date, slot, candidate);
                                  }
                                }
                              : null,
                          child: Text(l.replaceAction),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
