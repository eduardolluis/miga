import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/home/presentation/widgets/home_hero_height.dart';
import 'package:miga/features/home/presentation/widgets/meal_hero_card.dart';
import 'package:miga/features/recipes/domain/recipe.dart';

class HomeHeroCarousel extends StatefulWidget {
  const HomeHeroCarousel({
    super.key,
    required this.recipes,
    required this.onOpenRecipe,
    required this.onPlanRecipe,
  });
  final List<Recipe> recipes;
  final ValueChanged<Recipe>? onOpenRecipe;
  final ValueChanged<Recipe>? onPlanRecipe;

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> {
  final _controller = PageController(keepPage: false);
  int _page = 0;

  @override
  void didUpdateWidget(HomeHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipes.first.id != widget.recipes.first.id) {
      _page = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: homeHeroHeight(
              context,
              constraints.maxWidth,
              widget.recipes,
            ),
            child: PageView.builder(
              key: const ValueKey('home-hero-carousel'),
              controller: _controller,
              itemCount: widget.recipes.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) {
                final recipe = widget.recipes[index];
                return MealHeroCard(
                  recipe: recipe,
                  onOpen: widget.onOpenRecipe == null
                      ? null
                      : () => widget.onOpenRecipe!(recipe),
                  onPlan: widget.onPlanRecipe == null
                      ? null
                      : () => widget.onPlanRecipe!(recipe),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.recipes.length,
            (index) => Semantics(
              selected: _page == index,
              child: IconButton(
                tooltip: widget.recipes[index].contentFor(locale).title,
                onPressed: () => _controller.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                ),
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: index == _page ? 22 : 6,
                  height: 5,
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
