import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/core/ui/miga_ui_copy.dart';
import 'package:miga/features/home/application/home_controller.dart';
import 'package:miga/features/home/presentation/widgets/budget_recipe_suggestions.dart';
import 'package:miga/features/home/presentation/widgets/home_dashboard_quick_actions.dart';
import 'package:miga/features/recipes/data/recipe_catalog.dart';
import 'package:miga/features/meal_plan/presentation/meal_slot_presentation.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_image.dart';
import 'package:miga/l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.userName,
    required this.onProfile,
    this.onNotifications,
    required this.onPlan,
    required this.onEditMeal,
    required this.onRecipe,
    required this.onViewBudgetRecipes,
    this.onBrowseRecipes,
    this.onPreferences,
    this.onToggleFavorite,
    required this.onPlanRecipe,
    required this.onBudget,
    required this.onGroceries,
    required this.onStores,
    required this.onPro,
    this.onCookWithPantry,
    this.onFindCheaper,
    this.onSurprise,
    this.onGenerateWeek,
    this.surpriseRemaining = 3,
    this.surpriseBusy = false,
    this.isPro = false,
  });

  final HomeController controller;
  final String? userName;
  final VoidCallback onProfile;
  final VoidCallback? onNotifications;
  final VoidCallback onPlan;
  final VoidCallback onEditMeal;
  final ValueChanged<Recipe> onRecipe;
  final VoidCallback onViewBudgetRecipes;
  final VoidCallback? onBrowseRecipes;
  final VoidCallback? onPreferences;
  final ValueChanged<String>? onToggleFavorite;
  final ValueChanged<Recipe> onPlanRecipe;
  final VoidCallback onBudget;
  final VoidCallback onGroceries;
  final VoidCallback onStores;
  final VoidCallback onPro;
  final VoidCallback? onCookWithPantry;
  final VoidCallback? onFindCheaper;
  final VoidCallback? onSurprise;
  final VoidCallback? onGenerateWeek;
  final int surpriseRemaining;
  final bool surpriseBusy;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final enabled = controller.canEdit;
    final currentMeal = controller.mealFor(
      controller.today,
      controller.selectedSlot,
    );

    return ListView(
      key: const PageStorageKey('home-dashboard'),
      padding: const EdgeInsets.fromLTRB(22, 13, 22, 28),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Miga',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  fontSize: 33,
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('home-notifications'),
              onPressed: onNotifications,
              tooltip: l.notificationsTitle,
              icon: Badge(
                isLabelVisible: controller.pendingGroceries > 0,
                smallSize: 7,
                backgroundColor: const Color(0xFFE07932),
                child: const Icon(Icons.notifications_none_rounded, size: 25),
              ),
            ),
            IconButton(
              onPressed: onProfile,
              tooltip: l.homeAccount,
              icon: const Icon(Icons.account_circle_outlined, size: 26),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _BrandBanner(onPlan: onPlan, onGroceries: onGroceries),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                MigaUiCopy.today(context),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onPlan,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(l.homeViewPlan),
            ),
          ],
        ),
        const SizedBox(height: 5),
        _TodayMealCard(
          meal: currentMeal,
          slot: controller.selectedSlot.label(l),
          onTap: enabled ? onEditMeal : onPlan,
        ),
        if (controller.loadFailed) ...[
          Text(l.homeLoadError, textAlign: TextAlign.center),
          TextButton(onPressed: controller.load, child: Text(l.homeRetry)),
        ],
        // Never hide the entire recommendations section when the user has not
        // configured a weekly budget yet. Show two recipe ideas in that case;
        // budget-fit claims are made only when a valid budget exists.
        const SizedBox(height: 26),
        BudgetRecipeSuggestions(
          budget: controller.budgetCurrencyMatches ? controller.budget : null,
          currency: controller.preferences.currency,
          now: controller.now,
          recipes: RecipeCatalog.all
              .where(controller.preferences.allows)
              .map(controller.portionFor)
              .toList(),
          costFor: controller.costFor,
          pricing: controller.pricing || controller.loading,
          onRecipe: onRecipe,
          onSeeAll: onViewBudgetRecipes,
          favorites: controller.details.favorites,
          priceRevision: controller.priceRevision,
          ingredientPrices: controller.details.ingredientPrices,
          onFavorite: onToggleFavorite,
        ),
        const SizedBox(height: 26),
        HomeDashboardQuickActions(
          onCookWithPantry: onCookWithPantry ?? (onPreferences ?? onProfile),
          onFindCheaper: onFindCheaper ?? onPro,
          onSurprise: onSurprise ?? (onBrowseRecipes ?? onViewBudgetRecipes),
          onGenerateWeek: onGenerateWeek ?? onPro,
          surpriseRemaining: surpriseRemaining,
          surpriseBusy: surpriseBusy,
          isPro: isPro,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// The Home hero follows Miga's cream/olive editorial reference.
/// Its first slide is the user's selected reference; the other two are
/// navigable shortcuts rather than decorative, inert slides.
class _BrandBanner extends StatefulWidget {
  const _BrandBanner({required this.onPlan, required this.onGroceries});
  final VoidCallback onPlan;
  final VoidCallback onGroceries;

  @override
  State<_BrandBanner> createState() => _BrandBannerState();
}

class _BrandBannerState extends State<_BrandBanner> {
  final _page = PageController();
  int _selected = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spanish = MigaUiCopy.isSpanish(context);
    final slides = [
      (
        title: MigaUiCopy.hero(context),
        image: 'assets/images/home/banner-plan.webp',
        action: widget.onPlan,
      ),
      (
        title: spanish ? 'Tu semana,\na tu gusto.' : 'Your week,\nyour way.',
        image: 'assets/images/home/banner-recipes.webp',
        action: widget.onPlan,
      ),
      (
        title: spanish
            ? 'Compra solo\nlo necesario.'
            : 'Shop only\nwhat you need.',
        image: 'assets/images/home/banner-shop.webp',
        action: widget.onGroceries,
      ),
    ];
    return Column(
      children: [
        SizedBox(
          height: 194,
          child: PageView.builder(
            key: const ValueKey('home-featured-banner'),
            controller: _page,
            itemCount: slides.length,
            onPageChanged: (index) => setState(() => _selected = index),
            itemBuilder: (context, index) {
              final slide = slides[index];
              return Material(
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                color: const Color(0xFFE4ECD6),
                child: InkWell(
                  onTap: slide.action,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          slide.image,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(color: Color(0xFFE4ECD6)),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        width: 155,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 21),
                            child: Text(
                              slide.title,
                              maxLines: 4,
                              style: const TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 25,
                                height: 1.08,
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 11),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < slides.length; i++)
              Semantics(
                label: '${i + 1} / ${slides.length}',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _selected == i ? 9 : 8,
                  height: _selected == i ? 9 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selected == i
                        ? AppColors.olive
                        : const Color(0xFFD6D6CB),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TodayMealCard extends StatelessWidget {
  const _TodayMealCard({
    required this.meal,
    required this.slot,
    required this.onTap,
  });

  final String? meal;
  final String slot;
  final VoidCallback onTap;

  Recipe? _photoRecipe(BuildContext context) {
    if (meal == null) return null;
    final language = Localizations.localeOf(context).languageCode;
    final target = meal!.trim().toLowerCase();
    for (final recipe in RecipeCatalog.all) {
      if (recipe.contentFor(language).title.toLowerCase() == target ||
          recipe
                  .contentFor(language == 'es' ? 'en' : 'es')
                  .title
                  .toLowerCase() ==
              target) {
        return recipe;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photoRecipe(context);
    final emptyLabel = AppLocalizations.of(context)!.homeEmptyMeal;
    return Material(
      color: const Color(0xFFF1EEE7),
      borderRadius: BorderRadius.circular(19),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('home-today-meal'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1ECD7),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.event_available_outlined,
                  color: AppColors.olive,
                ),
              ),
              const SizedBox(width: 10),
              if (photo != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 62,
                    width: 64,
                    child: RecipeImage(index: photo.imageIndex),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      slot,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meal ?? emptyLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
