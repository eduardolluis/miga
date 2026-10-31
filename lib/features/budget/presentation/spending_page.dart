import 'package:flutter/material.dart';
import 'package:miga/features/home/application/home_controller.dart';
import 'package:miga/l10n/app_localizations.dart';

class SpendingPage extends StatelessWidget {
  const SpendingPage({super.key, required this.controller});
  final HomeController controller;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final weeks = controller.details.budgets.entries.toList()
      ..sort((a, b) {
        DateTime parse(String key) {
          final parts = key.split('-').map(int.parse).toList();
          return DateTime(parts[0], parts[1], parts[2]);
        }

        return parse(b.key).compareTo(parse(a.key));
      });
    return Scaffold(
      appBar: AppBar(title: Text(l.spendingTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(l.budgetDistinctionTip),
            const SizedBox(height: 24),
            if (weeks.isEmpty) Text(l.spendingEmpty),
            for (final entry in weeks)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        entry.key,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${l.homeBudget}: ${entry.value.format(entry.value.limit)}',
                      ),
                      Text(
                        '${l.actualSpending}: ${entry.value.format(entry.value.spent)}',
                      ),
                      Text(
                        '${l.remainingBudget}: ${entry.value.format(entry.value.limit - entry.value.spent)}',
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: entry.value.limit <= 0
                            ? 0
                            : (entry.value.spent / entry.value.limit).clamp(
                                0,
                                1,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
