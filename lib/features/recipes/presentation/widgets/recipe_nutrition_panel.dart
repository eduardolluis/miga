import 'package:flutter/material.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/l10n/app_localizations.dart';

class RecipeNutritionPanel extends StatefulWidget {
  const RecipeNutritionPanel({
    super.key,
    required this.nutrition,
    required this.servings,
  });

  final RecipeNutrition? nutrition;
  final int servings;

  @override
  State<RecipeNutritionPanel> createState() => _RecipeNutritionPanelState();
}

class _RecipeNutritionPanelState extends State<RecipeNutritionPanel> {
  bool _wholeRecipe = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final nutrition = widget.nutrition;
    if (nutrition == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration,
        child: Text(
          l.nutritionUnavailable,
          style: const TextStyle(color: AppColors.muted, height: 1.4),
        ),
      );
    }
    final wholeRecipe = _wholeRecipe && widget.servings > 1;
    final values = nutrition.scaled(
      wholeRecipe ? widget.servings.toDouble() : 1,
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.servings > 1)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _basisChoice(l.nutritionPerServing, false, wholeRecipe),
                _basisChoice(l.nutritionTotal, true, wholeRecipe),
              ],
            )
          else
            Text(
              l.nutritionPerServing,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 20),
          Text(
            l.nutritionCalories,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text.rich(
            key: const ValueKey('nutrition-calories'),
            TextSpan(
              text: '${values.calories}',
              style: const TextStyle(
                color: AppColors.olive,
                fontSize: 40,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
              children: const [
                TextSpan(
                  text: ' kcal',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked =
                  constraints.maxWidth < 240 ||
                  MediaQuery.textScalerOf(context).scale(14) > 21;
              final protein = _NutrientCard(
                label: l.nutritionProtein,
                grams: values.proteinGrams,
                valueKey: 'nutrition-protein',
              );
              final carbs = _NutrientCard(
                label: l.nutritionCarbs,
                grams: values.carbsGrams,
                valueKey: 'nutrition-carbs',
              );
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [protein, const SizedBox(height: 10), carbs],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: protein),
                    const SizedBox(width: 10),
                    Expanded(child: carbs),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            l.nutritionEstimateNote,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _basisChoice(String label, bool wholeRecipe, bool selected) =>
      ChoiceChip(
        key: ValueKey(
          wholeRecipe ? 'nutrition-whole-recipe' : 'nutrition-per-serving',
        ),
        label: Text(label),
        selected: wholeRecipe == selected,
        onSelected: (_) => setState(() => _wholeRecipe = wholeRecipe),
        selectedColor: const Color(0xFFE4EEDC),
        backgroundColor: Colors.transparent,
        side: BorderSide(
          color: wholeRecipe == selected ? Colors.transparent : AppColors.line,
        ),
        labelStyle: const TextStyle(
          color: AppColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: const StadiumBorder(),
      );
}

final _cardDecoration = BoxDecoration(
  color: const Color(0xFFFEFDF9),
  border: Border.all(color: AppColors.line),
  borderRadius: BorderRadius.circular(24),
);

class _NutrientCard extends StatelessWidget {
  const _NutrientCard({
    required this.label,
    required this.grams,
    required this.valueKey,
  });

  final String label, valueKey;
  final int grams;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F2E9),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Text(
          '$grams g',
          key: ValueKey(valueKey),
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
