import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

class HomeWeek extends StatelessWidget {
  const HomeWeek({
    super.key,
    required this.today,
    required this.selectedDate,
    required this.onSelected,
    required this.hasMeals,
    this.onViewPlan,
  });

  final DateTime today;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;
  final bool Function(DateTime date) hasMeals;
  final VoidCallback? onViewPlan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final monday = DateTime(
      today.year,
      today.month,
      today.day - today.weekday + 1,
    );
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.homeWeek,
                style: const TextStyle(
                  fontFamily: 'LiberationSerif',
                  fontSize: 25,
                ),
              ),
            ),
            if (onViewPlan != null)
              TextButton(onPressed: onViewPlan, child: Text(l10n.homeViewPlan)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${dates.formatMediumDate(monday)} — ${dates.formatMediumDate(sunday)}',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = math.max(
              (constraints.maxWidth - 36) / 7,
              MediaQuery.textScalerOf(context).scale(18) + 16,
            );
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(7, (index) {
                  final date = DateTime(
                    monday.year,
                    monday.month,
                    monday.day + index,
                  );
                  final selected = DateUtils.isSameDay(date, selectedDate);
                  final isToday = DateUtils.isSameDay(date, today);
                  final planned = hasMeals(date);
                  return Padding(
                    padding: EdgeInsets.only(right: index == 6 ? 0 : 6),
                    child: Semantics(
                      selected: selected,
                      button: true,
                      onTap: () => onSelected(date),
                      label:
                          '${dates.formatFullDate(date)}${isToday ? ', ${l10n.homeToday}' : ''}, ${planned ? l10n.homePlannedDay : l10n.homeEmptyDay}',
                      excludeSemantics: true,
                      child: Material(
                        color: selected ? AppColors.olive : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          key: ValueKey('home-day-${date.weekday}'),
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => onSelected(date),
                          child: SizedBox(
                            width: width,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                children: [
                                  Text(
                                    dates.narrowWeekdays[date.weekday % 7],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: selected
                                          ? Colors.white70
                                          : AppColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: planned
                                          ? selected
                                                ? Colors.white
                                                : AppColors.olive
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }
}
