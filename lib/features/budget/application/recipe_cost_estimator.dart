import 'dart:math' as math;

import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/budget/data/recipe_price_store.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/groceries/data/supermarket_price_source.dart';
import 'package:miga/features/groceries/domain/supermarket_offer.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';

class IngredientCost {
  const IngredientCost(
    this.amount, {
    this.cents,
    this.offer,
    this.purchaseCount,
  });
  final RecipeAmount amount;
  final int? purchaseCount;
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
    this.priceStore,
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
  final RecipePriceStore? priceStore;
  final _cache = <RecipeIngredient, List<SupermarketOffer>>{};
  final _pending = <RecipeIngredient, Future<void>>{};

  Future<void> restorePrices() async {
    if (priceStore == null) return;
    try {
      final saved = await priceStore!.load();
      for (final ingredient in RecipeIngredient.values) {
        final valid = (saved[ingredient.name] ?? [])
            .where(
              (o) =>
                  o.currency == 'DOP' &&
                  o.priceCents > 0 &&
                  !o.isStale &&
                  matchesOffer(ingredient, o),
            )
            .toList();
        if (valid.isNotEmpty) _cache[ingredient] = valid;
      }
    } catch (_) {
      // Catalog requests remain available if the local cache cannot be read.
    }
  }

  Future<void> _savePrices() async {
    if (priceStore == null) return;
    try {
      await priceStore!.save({
        for (final entry in _cache.entries)
          entry.key.name: List.of(entry.value),
      });
    } catch (_) {
      // A cache write failure must not hide successfully fetched prices.
    }
  }

  Future<List<RecipeCost>> estimate(
    List<Recipe> recipes, {
    void Function()? onProgress,
  }) async {
    final ingredients = recipes
        .expand(RecipeAmounts.forRecipe)
        .map((a) => a.ingredient)
        .toSet()
        .toList();
    for (var i = 0; i < ingredients.length; i += 3) {
      await Future.wait(
        ingredients.skip(i).take(3).map((ingredient) async {
          await _load(ingredient);
          onProgress?.call();
        }),
      );
      await _savePrices();
    }
    return recipes
        .map(
          (recipe) => RecipeCost(recipe, [
            for (final amount in RecipeAmounts.forRecipe(recipe)) _cost(amount),
          ]),
        )
        .toList();
  }

  static List<String> queriesFor(RecipeIngredient ingredient) {
    final query = switch (ingredient) {
      RecipeIngredient.banana => 'guineo maduro',
      RecipeIngredient.salmon => 'filete salmon',
      RecipeIngredient.bread => 'pan molde',
      RecipeIngredient.yogurt => 'yogurt natural',
      RecipeIngredient.mango => 'mango',
      RecipeIngredient.milk => 'leche entera',
      RecipeIngredient.tomatoes => 'tomate',
      RecipeIngredient.chicken => 'pechuga deshuesada',
      RecipeIngredient.herbs => 'hierbas',
      RecipeIngredient.chickpeas => 'garbanzos cocidos',
      RecipeIngredient.lentils => 'lentejas cocidas',
      RecipeIngredient.vegetableStock => 'caldo vegetales',
      RecipeIngredient.peanutButter => 'mantequilla mani',
      RecipeIngredient.groundBeef => 'carne molida',
      RecipeIngredient.tortilla => 'tortillas trigo',
      RecipeIngredient.blackBeans => 'habichuelas negras',
      RecipeIngredient.bellPepper => 'aji morron',
      _ => ingredient.es,
    };
    final alternatives = switch (ingredient) {
      RecipeIngredient.herbs => ['oregano'],
      RecipeIngredient.bellPepper => ['pimiento'],
      RecipeIngredient.zucchini => ['zucchini'],
      RecipeIngredient.garlic => ['ajo fresco'],
      RecipeIngredient.banana => ['guineo'],
      RecipeIngredient.salmon => ['salmon'],
      RecipeIngredient.bread => ['pan sandwich', 'pan'],
      RecipeIngredient.yogurt => ['yogur natural'],
      RecipeIngredient.mango => ['mango banilejo', 'mango grano oro'],
      RecipeIngredient.chicken => ['filete pollo', 'pechuga'],
      _ => <String>[],
    };
    return [query, ...alternatives];
  }

  RecipeCost costFromCache(Recipe recipe) => RecipeCost(recipe, [
    for (final amount in RecipeAmounts.forRecipe(recipe)) _cost(amount),
  ]);

  Future<void> _load(RecipeIngredient ingredient) =>
      _pending[ingredient] ??= _fetch(ingredient).whenComplete(() {
        _pending.remove(ingredient);
      });

  Future<void> _fetch(RecipeIngredient ingredient) async {
    final cached = _cache[ingredient];
    if (cached != null &&
        cached.isNotEmpty &&
        cached.every((o) => !o.isStale) &&
        cached.any((o) => matchesOffer(ingredient, o))) {
      return;
    }
    final reference = RecipeAmount(
      ingredient,
      1,
      RecipeAmounts.unitFor(ingredient),
    );
    final offers = <SupermarketOffer>[];
    for (final term in queriesFor(ingredient)) {
      try {
        final results = await _search(term);
        offers.addAll(
          results
              .expand((r) => r.offers)
              .where(
                (o) =>
                    o.currency == 'DOP' &&
                    o.priceCents > 0 &&
                    !o.isStale &&
                    o.store != Supermarket.pricesmart &&
                    matchesOffer(ingredient, o),
              ),
        );
        if (offers.any((o) => purchaseCost(reference, o).cents != null)) break;
      } catch (_) {}
    }
    _cache[ingredient] = offers;
  }

  IngredientCost _cost(RecipeAmount amount) {
    IngredientCost? best;
    for (final offer in _cache[amount.ingredient] ?? <SupermarketOffer>[]) {
      if (!matchesOffer(amount.ingredient, offer)) continue;
      final candidate = purchaseCost(amount, offer);
      if (candidate.cents != null &&
          (best?.cents == null || candidate.cents! < best!.cents!)) {
        best = candidate;
      }
    }
    return best ?? IngredientCost(amount);
  }

  // Approximate whole-produce weights, used only to choose complete unit packs.
  static const _pieceWeights = <RecipeIngredient, double>{
    RecipeIngredient.garlic: 50,
    RecipeIngredient.zucchini: 200,
    RecipeIngredient.onion: 150,
    RecipeIngredient.carrot: 80,
    RecipeIngredient.tomatoes: 120,
    RecipeIngredient.bellPepper: 150,
    RecipeIngredient.pineapple: 900,
  };

  static (double, CostUnit)? packageForOffer(SupermarketOffer offer) {
    final declaredUnit = switch (offer.measurementUnit) {
      'g' => CostUnit.grams,
      'ml' => CostUnit.milliliters,
      'un' => CostUnit.pieces,
      _ => null,
    };
    return declaredUnit != null &&
            offer.purchaseQuantity != null &&
            offer.purchaseQuantity! > 0
        ? (offer.purchaseQuantity!, declaredUnit)
        : packageAmount(offer.product);
  }

  static IngredientCost purchaseCost(
    RecipeAmount amount,
    SupermarketOffer offer,
  ) {
    if (offer.isStale ||
        offer.priceCents <= 0 ||
        !matchesOffer(amount.ingredient, offer)) {
      return IngredientCost(amount);
    }
    final pack = packageForOffer(offer);
    if (pack == null) return IngredientCost(amount);
    var needed = amount.amount;
    if (pack.$2 != amount.unit) {
      if (amount.unit == CostUnit.pieces &&
          pack.$2 == CostUnit.grams &&
          amount.gramsPerPiece != null) {
        needed *= amount.gramsPerPiece!;
      } else if (amount.unit == CostUnit.grams && pack.$2 == CostUnit.pieces) {
        final gramsPerPiece =
            amount.gramsPerPiece ?? _pieceWeights[amount.ingredient];
        if (gramsPerPiece == null) return IngredientCost(amount);
        needed /= gramsPerPiece;
      } else {
        return IngredientCost(amount);
      }
    }
    final count = (needed / pack.$1).ceil();
    return IngredientCost(
      amount,
      cents: offer.priceCents * count,
      offer: offer,
      purchaseCount: count,
    );
  }

  static const _freshProduce = {
    RecipeIngredient.mango,
    RecipeIngredient.banana,
    RecipeIngredient.apple,
    RecipeIngredient.pineapple,
    RecipeIngredient.strawberries,
    RecipeIngredient.avocado,
    RecipeIngredient.tomatoes,
    RecipeIngredient.potatoes,
    RecipeIngredient.broccoli,
    RecipeIngredient.lemon,
    RecipeIngredient.carrot,
    RecipeIngredient.garlic,
    RecipeIngredient.cucumber,
    RecipeIngredient.onion,
    RecipeIngredient.sweetPotato,
    RecipeIngredient.spinach,
    RecipeIngredient.celery,
    RecipeIngredient.bellPepper,
    RecipeIngredient.zucchini,
    RecipeIngredient.mushrooms,
    RecipeIngredient.basil,
  };

  static bool matchesOffer(
    RecipeIngredient ingredient,
    SupermarketOffer offer,
  ) {
    final categories = offer.categories.join(' ').toLowerCase();
    if (RegExp(
      r'mascotas|perros|gatos|cuidado personal|limpieza|juguetes|salud y belleza',
    ).hasMatch(categories)) {
      return false;
    }
    if (_freshProduce.contains(ingredient) &&
        RegExp(r'conserv|encurt|congelad|deshidrat|frutos secos')
            .hasMatch(categories)) {
      return false;
    }
    if (_freshProduce.contains(ingredient) &&
        categories.isNotEmpty &&
        !RegExp(r'frutas|vegetales|hortalizas|verduras|viveres|víveres')
            .hasMatch(categories)) {
      return false;
    }
    if (ingredient == RecipeIngredient.yogurt &&
        categories.contains('bebible')) {
      return false;
    }
    if ({
          RecipeIngredient.blackBeans,
          RecipeIngredient.chickpeas,
          RecipeIngredient.lentils,
        }.contains(ingredient) &&
        categories.isNotEmpty &&
        !RegExp(r'conserv|en lata|cocid').hasMatch(categories) &&
        !offer.product.toLowerCase().contains('cocid')) {
      return false;
    }
    return matchesIngredient(ingredient, offer.product);
  }

  static bool matchesIngredient(RecipeIngredient ingredient, String title) {
    var text = title.toLowerCase();
    for (final entry in {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ñ': 'n',
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
      RecipeIngredient.salmon:
          r'(?:(?:filetes?|lomitos?|lomos?) (?:de )?)?salmon',
      RecipeIngredient.potatoes: r'papas?',
      RecipeIngredient.broccoli: r'brocoli',
      RecipeIngredient.lemon: r'limon',
      RecipeIngredient.herbs: r'(?:hierbas|oregano)',
      RecipeIngredient.chicken:
          r'(?:(?:filete de )?pechuga|filete (?:de )?pollo)',
      RecipeIngredient.rice: r'(?:arroz|rice)',
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
      RecipeIngredient.vegetableStock: r'caldo (?:liquido )?(?:de )?vegetales',
      RecipeIngredient.apple: r'manzanas?',
      RecipeIngredient.peanutButter:
          r'(?:mantequilla|crema) (?:de )?(?:mani|cacahuete)',
      RecipeIngredient.tortilla: r'tortillas?',
      RecipeIngredient.blackBeans:
          r'(?:habichuelas?|frijoles?) (?:negras?|negros?)',
      RecipeIngredient.tuna: r'atun',
      RecipeIngredient.groundBeef: r'carne molida',
      RecipeIngredient.bellPepper: r'(?:pimiento|pimenton|aji morron)',
      RecipeIngredient.mushrooms: r'(?:champinon(?:es)?|hongos?)',
      RecipeIngredient.zucchini: r'(?:calabacin|zucchini)',
      RecipeIngredient.pineapple: r'pina',
      RecipeIngredient.tofu: r'tofu',
      RecipeIngredient.quinoa: r'(?:quinua|quinoa)',
    };
    if (!RegExp('^${starts[ingredient]!}\\b').hasMatch(text)) {
      return false;
    }
    if (RegExp(
      r'\b(?:gatos?|perros?|mascotas?|paws|alimento|pintura|jabon|shampoo|champu|acondicionador|ambientador|vela|crema corporal)\b',
    ).hasMatch(text)) {
      return false;
    }
    if (_freshProduce.contains(ingredient) &&
        RegExp(
          r'\b(?:deshidratad[oa]s?|sec[oa]s?|congelad[oa]s?|almibar|colada|compota|mermelada|nectar|zumo|jugo|pulpa|pure|conserva|enlatad[oa]s?|chips|frit[oa]s?|precocid[oa]s?|asada|molida|polvo|granulada|hojuelas|flakes|encurtid[oa]s?|vinagre)\b',
        ).hasMatch(text)) {
      return false;
    }
    if (ingredient == RecipeIngredient.yogurt &&
        (!RegExp(r'\b(?:natural|plain)\b').hasMatch(text) ||
            RegExp(
              r'\b(?:fresa|frambuesa|mango|vainilla|kefir|bebible|azucarado)\b',
            ).hasMatch(text))) {
      return false;
    }
    if (ingredient == RecipeIngredient.milk &&
        RegExp(r'\b(?:evaporada|condensada|polvo|saborizada)\b')
            .hasMatch(text)) {
      return false;
    }
    if (ingredient == RecipeIngredient.bread &&
        RegExp(r'\b(?:pita|hamburguesa|perro|hot dog|molido|rallado|dulce)\b')
            .hasMatch(text)) {
      return false;
    }
    if (ingredient == RecipeIngredient.chicken &&
        !RegExp(r'\b(?:sin hueso|deshuesada|filete)\b').hasMatch(text)) {
      return false;
    }
    if (ingredient == RecipeIngredient.chicken &&
        RegExp(r'\b(?:con hueso|empanizada|nuggets|sazonada)\b')
            .hasMatch(text)) {
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
        RegExp(r'\b(?:flakes|deshidratada|hojuelas|molida|granulada)\b')
            .hasMatch(text)) {
      return false;
    }
    if (ingredient == RecipeIngredient.sweetPotato &&
        RegExp(r'\b(?:fries|frita|precocida|asada)\b').hasMatch(text)) {
      return false;
    }
    if (ingredient == RecipeIngredient.tomatoes &&
        RegExp(r'\b(?:pelado|pelados|conserva|frito|fritos|passata|pure)\b')
            .hasMatch(text)) {
      return false;
    }
    if (ingredient == RecipeIngredient.cheese &&
        RegExp(r'\b(?:cottage|crema|untable)\b').hasMatch(text)) {
      return false;
    }
    // Do not price a wheat tortilla from an unrelated corn/egg tortilla.
    if (ingredient == RecipeIngredient.tortilla &&
        !RegExp(r'\btrigo\b').hasMatch(text)) {
      return false;
    }
    if (ingredient == RecipeIngredient.pepper && !text.contains('negra')) {
      return false;
    }
    if (ingredient == RecipeIngredient.walnuts &&
        RegExp(
          r'\b(?:mixtas?|dietz|macadamia|brazil|brasil|pecanas?|cascara)\b',
        ).hasMatch(text)) {
      return false;
    }
    if (ingredient == RecipeIngredient.banana &&
        RegExp(r'\b(?:verde|verdes|frito|chips)\b').hasMatch(text)) {
      return false;
    }
    return true;
  }

  static (double, CostUnit)? packageAmount(String title) {
    var text = title.toLowerCase().replaceAllMapped(
      RegExp(r'(\d),(\d)'),
      (m) => '${m[1]}.${m[2]}',
    );
    // Egg carton notation is a count, not a fractional weight (6/1 = six eggs).
    if (RegExp(r'\bhuevos?\b').hasMatch(text)) {
      final carton = RegExp(r'\b(\d+)\s*/\s*1\b').firstMatch(text);
      if (carton != null) {
        return (double.parse(carton[1]!), CostUnit.pieces);
      }
    }
    if (!text.contains('paq') &&
        RegExp(r'(?:,|\s)lb\.?\s*\(').hasMatch(text) &&
        !text.contains('peso aprox')) {
      return (453.59237, CostUnit.grams);
    }
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
      r'(\d+(?:\.\d+)?)\s*(kilogramos?|kg|gramos?|grs?|g|libras?|lbs?|onzas?|onz|oz|mililitros?|ml|litros?|lts?|lt|l|unidades|unidad|und|uds|ud|un)\b',
    ).allMatches(text).toList();
    final range = RegExp(
      r'\d+(?:\.\d+)?\s*(?:a|-)\s*\d+(?:\.\d+)?\s*(?:libra|lb|unidad)',
    ).firstMatch(text);
    if (range != null &&
        (matches.isEmpty || range.start <= matches.first.start)) {
      return null;
    }
    if (matches.isEmpty) {
      if (RegExp(r'\bpor unidad\b').hasMatch(text)) {
        return (1.0, CostUnit.pieces);
      }
      if (RegExp(r',\s*(?:und|unidad)\.?$').hasMatch(text)) {
        return (1.0, CostUnit.pieces);
      }
      return null;
    }
    final m = matches.first;
    final value = double.parse(m[1]!);
    if (value <= 0) return null;
    final unit = m[2]!;
    if ((unit == 'oz' || unit == 'onz') &&
        text.startsWith('caldo liquido') &&
        text.contains('vegetales')) {
      return (value * 29.5735295625, CostUnit.milliliters);
    }
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
        : unit == 'oz' || unit == 'onz' || unit.startsWith('onza')
        ? 28.349523
        : 1.0;
    return (value * factor, CostUnit.grams);
  }
}
