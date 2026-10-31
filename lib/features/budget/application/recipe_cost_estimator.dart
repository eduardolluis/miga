import 'dart:math' as math;

import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/groceries/data/supermarket_price_source.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';

class IngredientCost {
  const IngredientCost(this.amount, {this.cents, this.offer});
  final RecipeAmount amount;
  final int? cents;
  final SupermarketOffer? offer;
}

class RecipeCost {
  const RecipeCost(this.recipe, this.ingredients);
  final Recipe recipe;
  final List<IngredientCost> ingredients;
  bool get complete =>
      ingredients.isNotEmpty && ingredients.every((line) => line.cents != null);
  int get subtotalCents =>
      ingredients.fold(0, (sum, line) => sum + (line.cents ?? 0));
  int get perServingCents => recipe.servings > 0
      ? (subtotalCents / recipe.servings).round()
      : subtotalCents;
  bool fits(int allowance) => complete && subtotalCents <= allowance;
}

/// Number of breakfast/lunch/dinner opportunities remaining this calendar
/// week, including the current slot. Independent of how many meals are planned.
int remainingMealSlots(DateTime now) =>
    (7 - now.weekday) * 3 +
    (now.hour < 11
        ? 3
        : now.hour < 17
        ? 2
        : 1);

int mealAllowanceCents(WeeklyBudget budget, DateTime now) {
  final slots = remainingMealSlots(now);
  final remaining = budget.limit - budget.spent;
  if (slots <= 0 || !remaining.isFinite || remaining <= 0) return 0;
  return math.max(0, (remaining * 100 / slots).floor());
}

class RecipeCostEstimator {
  RecipeCostEstimator({
    Future<List<StoreSearchResult>> Function(String)? search,
  }) : _search =
           search ??
           ((query) => SupermarketPriceSource(resultLimit: 48).search(
             query,
             stores: {
               Supermarket.nacional,
               Supermarket.sirena,
               Supermarket.jumbo,
             },
           ));
  final Future<List<StoreSearchResult>> Function(String) _search;
  final _cache = <RecipeIngredient, List<SupermarketOffer>>{};

  Future<List<RecipeCost>> estimate(List<Recipe> recipes) async {
    final ingredients = recipes
        .expand(RecipeAmounts.forRecipe)
        .map((a) => a.ingredient)
        .toSet()
        .toList();
    for (var i = 0; i < ingredients.length; i += 3) {
      await Future.wait(ingredients.skip(i).take(3).map(_load));
    }
    return recipes
        .map(
          (recipe) => RecipeCost(recipe, [
            for (final amount in RecipeAmounts.forRecipe(recipe)) _cost(amount),
          ]),
        )
        .toList();
  }

  Future<void> _load(RecipeIngredient ingredient) async {
    final cached = _cache[ingredient];
    if (cached != null &&
        cached.isNotEmpty &&
        cached.every((o) => !o.isStale)) {
      return;
    }
    final query = switch (ingredient) {
      RecipeIngredient.milk => 'leche entera',
      RecipeIngredient.tomatoes => 'tomate',
      RecipeIngredient.chicken => 'pechuga pollo',
      RecipeIngredient.herbs => 'hierbas',
      RecipeIngredient.chickpeas => 'garbanzos cocidos',
      RecipeIngredient.lentils => 'lentejas cocidas',
      RecipeIngredient.vegetableStock => 'caldo vegetales liquido',
      _ => ingredient.es,
    };
    try {
      final results = await _search(query);
      _cache[ingredient] = results
          .expand((r) => r.offers)
          .where(
            (o) =>
                o.currency == 'DOP' &&
                o.priceCents > 0 &&
                !o.isStale &&
                o.store != Supermarket.pricesmart,
          )
          .toList();
    } catch (_) {
      _cache[ingredient] = [];
    }
  }

  IngredientCost _cost(RecipeAmount amount) {
    SupermarketOffer? selected;
    double? best;
    for (final offer in _cache[amount.ingredient] ?? <SupermarketOffer>[]) {
      if (!matchesIngredient(amount.ingredient, offer.product)) continue;
      final pack = packageAmount(offer.product);
      if (pack == null) continue;
      double needed = amount.amount;
      if (pack.$2 != amount.unit) {
        if (amount.unit == CostUnit.pieces &&
            pack.$2 == CostUnit.grams &&
            amount.gramsPerPiece != null) {
          needed *= amount.gramsPerPiece!;
        } else {
          continue;
        }
      }
      final cents = offer.priceCents * needed / pack.$1;
      if (best == null || cents < best) {
        best = cents;
        selected = offer;
      }
    }
    return IngredientCost(amount, cents: best?.ceil(), offer: selected);
  }

  static bool matchesIngredient(RecipeIngredient ingredient, String title) {
    var text = title.toLowerCase();
    for (final entry in {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
    }.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    const starts = <RecipeIngredient, String>{
      RecipeIngredient.oats: r'avena',
      RecipeIngredient.milk: r'leche',
      RecipeIngredient.banana: r'(?:banana|guineo)',
      RecipeIngredient.walnuts: r'(?:nuez|nueces)',
      RecipeIngredient.cinnamon: r'canela',
      RecipeIngredient.bread: r'pan',
      RecipeIngredient.avocado: r'aguacate',
      RecipeIngredient.eggs: r'huevos?',
      RecipeIngredient.tomatoes: r'tomates?',
      RecipeIngredient.oliveOil: r'aceite (?:de )?oliva',
      RecipeIngredient.salt: r'sal',
      RecipeIngredient.pepper: r'pimienta',
      RecipeIngredient.yogurt: r'yog(?:ur|urt)',
      RecipeIngredient.mango: r'mango',
      RecipeIngredient.strawberries: r'fresas?',
      RecipeIngredient.granola: r'granola',
      RecipeIngredient.salmon: r'salmon',
      RecipeIngredient.potatoes: r'papas?',
      RecipeIngredient.broccoli: r'brocoli',
      RecipeIngredient.lemon: r'limon',
      RecipeIngredient.herbs: r'hierbas',
      RecipeIngredient.chicken: r'pechuga',
      RecipeIngredient.rice: r'arroz',
      RecipeIngredient.carrot: r'zanahoria',
      RecipeIngredient.garlic: r'ajo',
      RecipeIngredient.chickpeas: r'garbanzos?',
      RecipeIngredient.cucumber: r'pepino',
      RecipeIngredient.onion: r'cebolla',
      RecipeIngredient.pasta: r'pasta',
      RecipeIngredient.basil: r'albahaca',
      RecipeIngredient.cheese: r'queso',
      RecipeIngredient.sweetPotato: r'batata',
      RecipeIngredient.spinach: r'espinaca',
      RecipeIngredient.lentils: r'lentejas?',
      RecipeIngredient.celery: r'apio',
      RecipeIngredient.vegetableStock: r'caldo (?:de )?vegetales',
    };
    if (!RegExp('^${starts[ingredient]!}\\b').hasMatch(text)) {
      return false;
    }
    if (RegExp(
      r'\b(?:sopa|vinagre|adobo|codorniz|mezcla|girasol|salsa|sazon|jugo|sabor|ahumado|condensada|polvo)\b',
    ).hasMatch(text)) {
      return false;
    }
    if (ingredient == RecipeIngredient.tomatoes &&
        RegExp(r'\b(?:con|secos?|triturados?|pasta)\b').hasMatch(text)) {
      return false;
    }
    if (ingredient == RecipeIngredient.garlic && text.contains('pasta')) {
      return false;
    }
    if (ingredient == RecipeIngredient.pasta &&
        RegExp(r'\b(?:dental|tomate|salsa)\b').hasMatch(text)) {
      return false;
    }
    if (ingredient == RecipeIngredient.garlic &&
        RegExp(r'\b(?:perejil|molido|granulado|deshidratado)\b')
            .hasMatch(text)) {
      return false;
    }
    if (ingredient == RecipeIngredient.onion &&
        RegExp(r'\b(?:flakes|deshidratada|hojuelas)\b').hasMatch(text)) {
      return false;
    }
    if (ingredient == RecipeIngredient.sweetPotato &&
        RegExp(r'\b(?:fries|frita|precocida|asada)\b').hasMatch(text)) {
      return false;
    }
    if (ingredient == RecipeIngredient.tomatoes &&
        RegExp(r'\b(?:pelado|pelados|conserva|frito|fritos)\b')
            .hasMatch(text)) {
      return false;
    }
    if (ingredient == RecipeIngredient.cheese &&
        RegExp(r'\b(?:cottage|crema|untable)\b').hasMatch(text)) {
      return false;
    }
    if (ingredient == RecipeIngredient.pepper && !text.contains('negra')) {
      return false;
    }
    return true;
  }

  static (double, CostUnit)? packageAmount(String title) {
    var text = title.toLowerCase().replaceAll(',', '.');
    if (text.contains('peso aprox')) {
      // A one-pound approximate pack has the same costing basis as a pound quote.
      if (RegExp(r'peso aprox\.?\s*1\s*(?:libra|lb)\b').hasMatch(text)) {
        return (453.59237, CostUnit.grams);
      }
      return null;
    }
    text = text.replaceAllMapped(RegExp(r'(\d+)\s*/\s*(\d+)'), (m) {
      final denominator = double.parse(m[2]!);
      return denominator == 0
          ? 'unknown'
          : (double.parse(m[1]!) / denominator).toString();
    });
    // Reject multipacks until their total content can be established explicitly.
    if (RegExp(r'\d+\s*[x×]\s*\d+').hasMatch(text)) return null;
    final matches = RegExp(
      r'(\d+(?:\.\d+)?)\s*(kilogramos?|kg|gramos?|grs?|g|libras?|lbs?|onzas?|oz|mililitros?|ml|litros?|lts?|lt|l|unidades|unidad|und|uds|ud|un)\b',
    ).allMatches(text).toList();
    if (matches.isEmpty) return null;
    final m = matches.first;
    final value = double.parse(m[1]!);
    if (value <= 0) return null;
    final unit = m[2]!;
    if (['ml', 'mililitro', 'mililitros'].contains(unit)) {
      return (value, CostUnit.milliliters);
    }
    if (['l', 'lt', 'lts', 'litro', 'litros'].contains(unit)) {
      return (value * 1000, CostUnit.milliliters);
    }
    if (unit.startsWith('un') || ['ud', 'uds'].contains(unit)) {
      return (value, CostUnit.pieces);
    }
    final factor = unit == 'kg' || unit.startsWith('kilogram')
        ? 1000.0
        : unit.startsWith('lb') || unit.startsWith('libra')
        ? 453.59237
        : unit == 'oz' || unit.startsWith('onza')
        ? 28.349523
        : 1.0;
    return (value * factor, CostUnit.grams);
  }
}
