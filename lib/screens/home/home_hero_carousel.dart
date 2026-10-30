import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/home_details.dart';
import '../../theme/app_colors.dart';
import 'home_budget_card.dart';
import 'home_hero_height.dart';
import 'meal_slot.dart';

class HomeHeroCarousel extends StatefulWidget {
  const HomeHeroCarousel({
    super.key,
    required this.selectedDate,
    required this.slot,
    required this.meal,
    required this.budget,
    required this.onSlot,
    required this.onEditMeal,
    required this.onRecipe,
    required this.onBudget,
  });

  final DateTime selectedDate;
  final MealSlot slot;
  final String? meal;
  final WeeklyBudget? budget;
  final ValueChanged<MealSlot> onSlot;
  final VoidCallback? onEditMeal;
  final VoidCallback? onRecipe;
  final VoidCallback? onBudget;

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void didUpdateWidget(HomeHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate &&
        _controller.hasClients) {
      _controller.animateToPage(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: homeHeroHeight(
              context,
              width: constraints.maxWidth,
              date: widget.selectedDate,
              meal: widget.meal,
              budget: widget.budget,
            ),
            child: PageView(
              key: const PageStorageKey('home-hero-carousel'),
              controller: _controller,
              onPageChanged: (page) => setState(() => _page = page),
              children: [
                _MealHero(
                  date: widget.selectedDate,
                  slot: widget.slot,
                  meal: widget.meal,
                  onSlot: widget.onSlot,
                  onEdit: widget.onEditMeal,
                  onRecipe: widget.onRecipe,
                ),
                HomeBudgetCard(budget: widget.budget, onEdit: widget.onBudget),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            2,
            (index) => Semantics(
              selected: index == _page,
              child: IconButton(
                tooltip: index == 0
                    ? l10n.homeCarouselPlan
                    : l10n.homeCarouselBudget,
                onPressed: () => _controller.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                ),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 6,
                  width: index == _page ? 22 : 6,
                  decoration: BoxDecoration(
                    color: index == _page
                        ? AppColors.olive
                        : const Color(0xFFD5D7CA),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MealHero extends StatelessWidget {
  const _MealHero({
    required this.date,
    required this.slot,
    required this.meal,
    required this.onSlot,
    required this.onEdit,
    required this.onRecipe,
  });

  final DateTime date;
  final MealSlot slot;
  final String? meal;
  final ValueChanged<MealSlot> onSlot;
  final VoidCallback? onEdit;
  final VoidCallback? onRecipe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (meal == null || meal == l10n.homeRecipeTitle)
            Image.asset(
              'assets/images/home/lemon-salmon.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.25),
              excludeFromSemantics: true,
            )
          else
            const ColoredBox(color: AppColors.olive),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x990D180C),
                  Color(0x330D180C),
                  Color(0xAD0D180C),
                  Color(0xF50D180C),
                ],
                stops: [0, 0.25, 0.65, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: MealSlot.values
                        .map(
                          (value) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(value.label(l10n)),
                              selected: slot == value,
                              onSelected: (_) => onSlot(value),
                              showCheckmark: false,
                              backgroundColor: const Color(0xDD152213),
                              selectedColor: AppColors.cream,
                              shape: const StadiumBorder(),
                              side: BorderSide.none,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                color: slot == value
                                    ? AppColors.ink
                                    : Colors.white,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const Spacer(),
                Text(
                  '${l10n.homeTodayPlan} · ${MaterialLocalizations.of(context).formatShortDate(date)}',
                  style: const TextStyle(
                    color: Color(0xFFE6EBDD),
                    fontSize: 12,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  meal ?? l10n.homeEmptyHeroTitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'LiberationSerif',
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                if (meal == null)
                  Text(
                    l10n.homeEmptyHeroDescription,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.olive,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(14),
                    ),
                    onPressed: onEdit,
                    child: Text(
                      meal == null ? l10n.homeAddMeal : l10n.homeEditMeal,
                    ),
                  ),
                ),
                Center(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size(48, 40),
                    ),
                    onPressed: onRecipe,
                    child: Text(
                      meal == l10n.homeRecipeTitle
                          ? l10n.homeViewRecipe
                          : l10n.homeRecipeIdea,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
