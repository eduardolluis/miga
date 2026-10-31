import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/l10n/app_localizations.dart';

class HomeWeek extends StatefulWidget {
  const HomeWeek({
    super.key,
    required this.today,
    required this.selectedDate,
    required this.onSelected,
    required this.hasMeals,
    required this.meal,
    required this.slotLabel,
    required this.onEditMeal,
    this.onViewPlan,
    this.mealCount = 0,
    this.remainingBudget,
    this.todayMeal,
  });
  final DateTime today;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;
  final bool Function(DateTime) hasMeals;
  final String? meal;
  final String slotLabel;
  final VoidCallback? onEditMeal;
  final VoidCallback? onViewPlan;
  final int mealCount;
  final String? remainingBudget;
  final String? todayMeal;

  @override
  State<HomeWeek> createState() => _HomeWeekState();
}

class _HomeWeekState extends State<HomeWeek> {
  final _scroll = ScrollController(keepScrollOffset: false);
  final _selectedDay = GlobalKey();
  DateTime? _lastRevealedDate;

  void _revealSelectedDay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (_lastRevealedDate != null &&
          DateUtils.isSameDay(_lastRevealedDate, widget.selectedDate)) {
        return;
      }
      final target = _selectedDay.currentContext;
      if (target != null) {
        final renderObject = target.findRenderObject();
        if (renderObject != null) {
          _scroll.position.ensureVisible(renderObject, alignment: 0.5);
        }
        _lastRevealedDate = widget.selectedDate;
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final monday = DateTime(
      widget.today.year,
      widget.today.month,
      widget.today.day - widget.today.weekday + 1,
    );
    _revealSelectedDay();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFDF9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
              TextButton(
                onPressed: widget.onViewPlan,
                child: Text(l10n.homeViewPlan),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.homeMealsPlanned(widget.mealCount),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.olive,
                  ),
                ),
              ),
              if (widget.remainingBudget != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.remainingBudget} ${l10n.localeName.startsWith('es') ? 'restante' : 'remaining'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.olive,
                    ),
                  ),
                ),
            ],
          ),
          if (widget.mealCount == 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAF6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.olive,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.homeWeekEmpty,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...List.generate(7, (index) {
                  final dayWidth = math.max(
                    62.0,
                    MediaQuery.textScalerOf(context).scale(18) + 24,
                  );
                  final date = DateTime(
                    monday.year,
                    monday.month,
                    monday.day + index,
                  );
                  final selected = DateUtils.isSameDay(
                    widget.selectedDate,
                    date,
                  );
                  final planned = widget.hasMeals(date);
                  return Padding(
                    padding: EdgeInsets.only(right: index == 6 ? 0 : 12),
                    child: Semantics(
                      label:
                          '${dates.formatFullDate(date)}, ${planned ? l10n.homePlannedDay : l10n.homeEmptyDay}',
                      selected: selected,
                      button: true,
                      onTap: () => widget.onSelected(date),
                      excludeSemantics: true,
                      child: Material(
                        key: selected ? _selectedDay : null,
                        color: selected
                            ? AppColors.olive
                            : const Color(0xFFF3F4EC),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          key: ValueKey('home-day-${date.weekday}'),
                          onTap: () => widget.onSelected(date),
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: dayWidth,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              child: Column(
                                children: [
                                  Text(
                                    DateFormat.E(l10n.localeName).format(date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: selected
                                          ? Colors.white70
                                          : AppColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: !planned
                                          ? Colors.transparent
                                          : selected
                                          ? Colors.white
                                          : AppColors.olive,
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
                const SizedBox(width: 28),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 16),
          Text(
            '${widget.slotLabel} · ${dates.formatMediumDate(widget.selectedDate)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            widget.meal ?? l10n.homeEmptyDay,
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              fontWeight: widget.meal == null
                  ? FontWeight.w400
                  : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: widget.onEditMeal,
              style: FilledButton.styleFrom(
                foregroundColor: AppColors.olive,
                backgroundColor: const Color(0xFFE8EBDF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              icon: Icon(
                widget.meal == null ? Icons.add : Icons.edit_outlined,
                size: 18,
              ),
              label: Text(
                widget.meal == null ? l10n.homeAddMeal : l10n.homeEditMeal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
