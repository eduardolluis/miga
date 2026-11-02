import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/recipes/domain/recipe_amount.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
import 'package:miga/features/recipes/domain/recipe_photo.dart';

class RecipeNutrition {
  const RecipeNutrition({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    this.fatGrams,
    this.estimated = true,
  });
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int? fatGrams;
  final bool estimated;
  RecipeNutrition scaled(double factor) => RecipeNutrition(
    calories: (calories * factor).round(),
    proteinGrams: (proteinGrams * factor).round(),
    carbsGrams: (carbsGrams * factor).round(),
    fatGrams: fatGrams == null ? null : (fatGrams! * factor).round(),
    estimated: estimated,
  );
  Map<String, Object?> toJson() => {
    'calories': calories,
    'protein_grams': proteinGrams,
    'carbs_grams': carbsGrams,
    'fat_grams': fatGrams,
    'estimated': estimated,
  };
}

class RecipeContent {
  const RecipeContent({
    required this.title,
    required this.description,
    required this.ingredients,
    required this.steps,
  });
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  Map<String, Object> toJson() => {
    'title': title,
    'description': description,
    'ingredients': ingredients,
    'steps': steps,
  };
  factory RecipeContent.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String;
    final description = json['description'] as String;
    final ingredients = List<String>.from(json['ingredients'] as List);
    final steps = List<String>.from(json['steps'] as List);
    if (title.trim().isEmpty ||
        description.trim().isEmpty ||
        ingredients.isEmpty ||
        steps.isEmpty ||
        [...ingredients, ...steps].any((s) => s.trim().isEmpty)) {
      throw const FormatException('Incomplete recipe translation');
    }
    return RecipeContent(
      title: title,
      description: description,
      ingredients: List.unmodifiable(ingredients),
      steps: List.unmodifiable(steps),
    );
  }
}

class Recipe {
  const Recipe({
    required this.id,
    required this.ingredients,
    required this.slot,
    required this.minutes,
    required this.servings,
    required this.photo,
    required this.es,
    required this.en,
    this.nutrition,
    this.amounts = const [],
    this.baseServings = 2,
    this.sortOrder = 0,
    this.tags = const [],
    this.source = 'miga-original',
  });
  final String id;
  final Set<RecipeIngredient> ingredients;
  final RecipeNutrition? nutrition;
  final MealSlot slot;
  final int minutes;
  final int servings;
  final int baseServings;
  final RecipePhoto photo;
  final int sortOrder;
  final List<RecipeAmount> amounts;
  final List<String> tags;
  final String source;
  final RecipeContent es;
  final RecipeContent en;
  int matchingIngredients(Set<RecipeIngredient> available) =>
      ingredients.intersection(available).length;
  RecipeContent contentFor(String languageCode) =>
      languageCode == 'es' ? es : en;
  Recipe withServings(int value) {
    if (value < 1 || value > 24) throw ArgumentError.value(value, 'servings');
    return Recipe(
      id: id,
      ingredients: ingredients,
      slot: slot,
      minutes: minutes,
      servings: value,
      photo: photo,
      es: es,
      en: en,
      nutrition: nutrition,
      amounts: amounts,
      baseServings: baseServings,
      sortOrder: sortOrder,
      tags: tags,
      source: source,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'slot': slot.name,
    'minutes': minutes,
    'servings': baseServings,
    'sort_order': sortOrder,
    'photo': photo.toJson(),
    'nutrition': nutrition?.toJson(),
    'amounts': [
      for (final a in amounts)
        {
          'ingredient': a.ingredient.name,
          'amount': a.amount,
          'unit': a.unit.name,
          if (a.gramsPerPiece != null) 'grams_per_piece': a.gramsPerPiece,
        },
    ],
    'es': es.toJson(),
    'en': en.toJson(),
    'tags': tags,
    'source': source,
  };
  factory Recipe.fromJson(
    Map<String, dynamic> json, {
    String imageBaseUrl = '',
  }) {
    final id = json['id'] as String;
    final servings = json['servings'] as int;
    final minutes = json['minutes'] as int;
    final photo = json['photo'] as Map<String, dynamic>;
    var path = photo['path'] as String;
    final width = photo['width'] as int;
    final height = photo['height'] as int;
    final thumbnailPath = photo['thumbnail_path'] as String?;
    final thumbnailWidth = photo['thumbnail_width'] as int?;
    final thumbnailHeight = photo['thumbnail_height'] as int?;
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(id) ||
        servings < 1 ||
        servings > 24 ||
        minutes < 1 ||
        minutes > 1440 ||
        width < 1 ||
        height < 1 ||
        path.isEmpty ||
        path.contains('..') ||
        (thumbnailPath == null &&
            (thumbnailWidth != null || thumbnailHeight != null)) ||
        (thumbnailPath != null &&
            (thumbnailWidth == null || thumbnailHeight == null)) ||
        (thumbnailPath != null &&
            (!RegExp(r'^[a-zA-Z0-9_/-]+[.](jpg|jpeg|webp|png)$')
                    .hasMatch(thumbnailPath) ||
                thumbnailPath.startsWith('/') ||
                thumbnailPath.contains('..') ||
                (thumbnailWidth ?? 0) < 1 ||
                (thumbnailHeight ?? 0) < 1))) {
      throw const FormatException('Invalid recipe metadata');
    }
    if (!path.startsWith('https://')) {
      // Photo paths in Supabase are relative to the recipe-photos bucket.
      // Reject old bundled asset references rather than silently reintroducing
      // mocks when a stale local catalog is read.
      if (path.startsWith('assets/') ||
          path.startsWith('http://') ||
          path.startsWith('/') ||
          !RegExp(r'^[a-zA-Z0-9_/-]+[.](jpg|jpeg|webp|png)$').hasMatch(path)) {
        throw const FormatException('Unsupported recipe photo path');
      }
      path = '$imageBaseUrl$path';
    }
    final amounts = [
      for (final raw in json['amounts'] as List)
        _amount(Map<String, dynamic>.from(raw as Map)),
    ];
    if (amounts.isEmpty ||
        amounts.map((a) => a.ingredient).toSet().length != amounts.length) {
      throw const FormatException('Missing or duplicate ingredient quantities');
    }
    final n = json['nutrition'] as Map<String, dynamic>?;
    if (n != null &&
        [
          'calories',
          'protein_grams',
          'carbs_grams',
          'fat_grams',
        ].any((k) => n[k] != null && (n[k] is! int || (n[k] as int) < 0))) {
      throw const FormatException('Invalid nutrition');
    }
    return Recipe(
      id: id,
      ingredients: Set.unmodifiable(amounts.map((a) => a.ingredient)),
      slot: MealSlot.values.byName(json['slot'] as String),
      minutes: minutes,
      servings: servings,
      baseServings: servings,
      sortOrder: json['sort_order'] as int,
      photo: RecipePhoto(
        path,
        width,
        height,
        thumbnailPath: thumbnailPath == null
            ? null
            : thumbnailPath.startsWith('https://')
            ? thumbnailPath
            : '$imageBaseUrl$thumbnailPath',
        thumbnailWidth: thumbnailWidth,
        thumbnailHeight: thumbnailHeight,
      ),
      amounts: List.unmodifiable(amounts),
      es: RecipeContent.fromJson(json['es'] as Map<String, dynamic>),
      en: RecipeContent.fromJson(json['en'] as Map<String, dynamic>),
      nutrition: n == null
          ? null
          : RecipeNutrition(
              calories: n['calories'] as int,
              proteinGrams: n['protein_grams'] as int,
              carbsGrams: n['carbs_grams'] as int,
              fatGrams: n['fat_grams'] as int?,
              estimated: n['estimated'] as bool? ?? true,
            ),
      tags: List.unmodifiable(List<String>.from(json['tags'] as List? ?? [])),
      source: json['source'] as String,
    );
  }
  static RecipeAmount _amount(Map<String, dynamic> json) {
    final value = (json['amount'] as num).toDouble();
    final grams = (json['grams_per_piece'] as num?)?.toDouble();
    if (!value.isFinite ||
        value <= 0 ||
        value > 1000000 ||
        (grams != null && (!grams.isFinite || grams <= 0))) {
      throw const FormatException('Invalid ingredient quantity');
    }
    return RecipeAmount(
      RecipeIngredient.values.byName(json['ingredient'] as String),
      value,
      CostUnit.values.byName(json['unit'] as String),
      gramsPerPiece: grams,
    );
  }
}
