import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/recipes/data/recipe_repository.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/meal_plan/domain/planned_recipe.dart';

import '../../../support/recipe_catalog.dart';

class _Cache implements RecipeCache {
  String? value;
  bool failWrite = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String next) async {
    if (failWrite) throw StateError('disk full');
    value = next;
  }
}

class _Source implements RecipeSource {
  List<Map<String, dynamic>> rows = [RecipeCatalog.all.first.toJson()];
  Object? failure;
  Completer<List<Map<String, dynamic>>>? pending;
  int calls = 0;
  List<String>? searchedIds;
  int? offset;
  @override
  String get imageBaseUrl => 'https://example.com/photos/';
  @override
  Future<List<Map<String, dynamic>>> snapshot() async {
    calls++;
    if (failure != null) throw failure!;
    return pending?.future ?? rows;
  }

  @override
  Future<Map<String, dynamic>> search({
    required List<String> orderedIds,
    required String query,
    required String language,
    MealSlot? slot,
    required int offset,
    required int limit,
  }) async {
    searchedIds = orderedIds;
    this.offset = offset;
    if (failure != null) throw failure!;
    final filtered =
        rows
            .where(
              (r) =>
                  orderedIds.contains(r['id']) &&
                  (slot == null || r['slot'] == slot.name) &&
                  (r[language] as Map)['title']
                      .toString()
                      .toLowerCase()
                      .contains(query.toLowerCase()),
            )
            .toList()
          ..sort(
            (a, b) => orderedIds
                .indexOf(a['id'] as String)
                .compareTo(orderedIds.indexOf(b['id'] as String)),
          );
    return {
      'recipes': filtered.skip(offset).take(limit).toList(),
      'total': filtered.length,
    };
  }
}

void main() {
  test(
    'First load reads actual remote data and persists a restartable cache',
    () async {
      final cache = _Cache();
      final source = _Source();
      final repo = RecipeRepository(source: source, cache: cache);
      addTearDown(repo.dispose);
      await Future.wait([repo.initialize(), repo.initialize()]);
      expect(source.calls, 1);
      expect(repo.all.single.id, RecipeCatalog.all.first.id);
      expect(repo.offline, isFalse);
      expect(jsonDecode(cache.value!)['schema_version'], 1);
      final offline = RecipeRepository(
        source: _Source()..failure = StateError('offline'),
        cache: cache,
      );
      addTearDown(offline.dispose);
      await offline.initialize();
      await offline.refresh();
      expect(offline.all.single.id, repo.all.single.id);
      expect(offline.offline, isTrue);
      expect(offline.error, isNotNull);
    },
  );
  test('Cache displays immediately while revalidation waits; corrupt caches invent nothing', () async {
    final cache = _Cache()
      ..value = jsonEncode({
        'schema_version': 1,
        'recipes': [RecipeCatalog.all.first.toJson()],
      });
    final source = _Source()..pending = Completer();
    final repo = RecipeRepository(source: source, cache: cache);
    addTearDown(repo.dispose);
    await repo.initialize();
    expect(repo.all, hasLength(1));
    expect(repo.loading, isTrue);
    source.pending!.complete([RecipeCatalog.all.last.toJson()]);
    await repo.refresh();
    expect(repo.all.single.id, RecipeCatalog.all.last.id);
    final broken = RecipeRepository(
      source: _Source()..failure = StateError('offline'),
      cache: _Cache()..value = 'not json',
    );
    addTearDown(broken.dispose);
    await broken.initialize();
    expect(broken.all, isEmpty);
    expect(broken.loading, isFalse);
    expect(broken.error, isNotNull);
  });
  test('Invalid updates preserve the full last valid snapshot', () async {
    final source = _Source();
    final cache = _Cache();
    final repo = RecipeRepository(source: source, cache: cache);
    addTearDown(repo.dispose);
    await repo.initialize();
    final previousCache = cache.value;
    source.rows = [
      RecipeCatalog.all.last.toJson(),
      {...RecipeCatalog.all.first.toJson(), 'amounts': []},
    ];
    await repo.refresh();
    expect(repo.all.single.id, RecipeCatalog.all.first.id);
    expect(cache.value, previousCache);
    expect(repo.offline, isTrue);
  });
  test('Retired recipes stay resolvable in saved plans after restart, not discovery', () async {
    final source = _Source();
    final cache = _Cache();
    final repo = RecipeRepository(source: source, cache: cache);
    addTearDown(repo.dispose);
    await repo.initialize();
    final old = repo.all.single;
    source.rows = [RecipeCatalog.all.last.toJson()];
    await repo.refresh();
    expect(repo.all.any((r) => r.id == old.id), isFalse);
    final plan = PlannedRecipe.parse('@miga:${old.id}:4')!;
    expect(plan.resolve(repo.known)!.servings, 4);
    expect(
      PlannedRecipe.parse(old.es.title, recipes: repo.known)!.recipeId,
      old.id,
    );
    final restarted = RecipeRepository(
      source: _Source()..failure = StateError('offline'),
      cache: cache,
    );
    addTearDown(restarted.dispose);
    await restarted.initialize();
    await restarted.refresh();
    expect(plan.resolve(restarted.known)!.id, old.id);
  });
  test('Search delegates pages and applies saved portions; network failures use real cache', () async {
    final source = _Source()
      ..rows = RecipeCatalog.all.take(10).map((r) => r.toJson()).toList();
    final repo = RecipeRepository(source: source);
    addTearDown(repo.dispose);
    await repo.initialize();
    final eligible = repo.all.reversed.map((r) => r.withServings(5)).toList();
    final page = await repo.search(eligible: eligible, page: 1);
    expect(source.offset, 6);
    expect(page.total, 10);
    expect(page.recipes.map((r) => r.id), eligible.skip(6).map((r) => r.id));
    expect(page.recipes.every((r) => r.servings == 5), isTrue);
    source.failure = StateError('offline');
    final fallback = await repo.search(eligible: eligible, page: 1);
    expect(fallback.recipes.map((r) => r.id), page.recipes.map((r) => r.id));
    expect(fallback.offline, isTrue);
  });
  test('Disk failures keep fresh remote content usable', () async {
    final repo = RecipeRepository(
      source: _Source(),
      cache: _Cache()..failWrite = true,
    );
    addTearDown(repo.dispose);
    await repo.initialize();
    expect(repo.all, hasLength(1));
    expect(repo.error, isNull);
  });
  test('Imported recipes scale quantities by their actual base servings', () {
    final json = RecipeCatalog.all.first.toJson()..['servings'] = 3;
    final recipe = Recipe.fromJson(json).withServings(6);
    final amounts = RecipeAmounts.forRecipe(recipe);
    expect(amounts.first.amount, recipe.amounts.first.amount * 2);
    final roundTrip = Recipe.fromJson(recipe.toJson());
    expect(roundTrip.baseServings, 3);
    expect(roundTrip.amounts.first.amount, recipe.amounts.first.amount);
  });
  test('Unknown ingredients and duplicate IDs fail instead of weakening restrictions', () async {
    final bad = jsonDecode(
      jsonEncode(RecipeCatalog.all.first.toJson()),
    ) as Map<String, dynamic>;
    (bad['amounts'] as List).first['ingredient'] = 'unrecognized-allergen';
    expect(() => Recipe.fromJson(bad), throwsArgumentError);
    final source = _Source()
      ..rows = [
        RecipeCatalog.all.first.toJson(),
        RecipeCatalog.all.first.toJson(),
      ];
    final repo = RecipeRepository(source: source);
    addTearDown(repo.dispose);
    await repo.initialize();
    expect(repo.all, isEmpty);
    expect(repo.error, isNotNull);
  });
}
