import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/home/presentation/widgets/home_hero_height.dart';
import 'package:miga/features/home/presentation/widgets/meal_hero_card.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/l10n/app_localizations.dart';

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
  late final _controller = PageController(
    keepPage: false,
    initialPage: widget.recipes.length * 1000,
  );
  late int _page = widget.recipes.length * 1000;

  @override
  void didUpdateWidget(HomeHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipes.map((r) => r.id).join(',') !=
        widget.recipes.map((r) => r.id).join(',')) {
      _page = widget.recipes.length * 1000;
      if (_controller.hasClients) _controller.jumpToPage(_page);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recipes.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final active = _page % widget.recipes.length;
    void move(int delta) => _controller.animateToPage(
      _page + delta,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
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
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) {
                final recipe = widget.recipes[index % widget.recipes.length];
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
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              style: IconButton.styleFrom(
                foregroundColor: AppColors.muted,
                minimumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
              ),
              tooltip: l10n.carouselPrevious,
              onPressed: _page > 0 ? () => move(-1) : null,
              icon: const Icon(Icons.arrow_back_rounded, size: 17),
            ),
            Expanded(
              child: Text(
                l10n.carouselPosition(active + 1, widget.recipes.length),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
            IconButton(
              style: IconButton.styleFrom(
                foregroundColor: AppColors.muted,
                minimumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
              ),
              tooltip: l10n.carouselNext,
              onPressed: () => move(1),
              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            ),
          ],
        ),
      ],
    );
  }
}
