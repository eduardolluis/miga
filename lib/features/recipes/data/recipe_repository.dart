import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/recipes/domain/recipe.dart';

abstract interface class RecipeCache {
  Future<String?> read();
  Future<void> write(String value);
}

class LocalRecipeCache implements RecipeCache {
  LocalRecipeCache(this.namespace);
  final String namespace;
  String get _key => 'miga.catalog.v1.$namespace';
  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);
  @override
  Future<void> write(String value) async {
    if (!await (await SharedPreferences.getInstance()).setString(_key, value)) {
      throw StateError('Recipe cache could not be saved');
    }
  }
}

class RecipePage {
  const RecipePage(this.recipes, this.total, {this.offline = false});
  final List<Recipe> recipes;
  final int total;
  final bool offline;
}

abstract interface class RecipeSource {
  String get imageBaseUrl;
  Future<List<Map<String, dynamic>>> snapshot();
  Future<Map<String, dynamic>> search({
    required List<String> orderedIds,
    required String query,
    required String language,
    MealSlot? slot,
    required int offset,
    required int limit,
  });
}

class SupabaseRecipeSource implements RecipeSource {
  SupabaseRecipeSource(this.client);
  final SupabaseClient client;
  @override
  String get imageBaseUrl {
    // Using an explicit object name avoids assumptions about the separator
    // returned by future versions of the Supabase Storage SDK.
    const probe = '__miga_public_photo_base__';
    final url = client.storage.from('recipe-photos').getPublicUrl(probe);
    return url.substring(0, url.length - probe.length);
  }
  @override
  Future<List<Map<String, dynamic>>> snapshot() async {
    // One SQL snapshot avoids mixing pages from different catalog revisions.
    final response = await client
        .rpc('miga_recipe_snapshot')
        .timeout(const Duration(seconds: 12));
    return (response as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> search({
    required List<String> orderedIds,
    required String query,
    required String language,
    MealSlot? slot,
    required int offset,
    required int limit,
  }) async => Map<String, dynamic>.from(
    await client
            .rpc(
              'miga_search_recipes',
              params: {
                'p_ids': orderedIds,
                'p_query': query,
                'p_language': language,
                'p_slot': slot?.name,
                'p_offset': offset,
                'p_limit': limit,
              },
            )
            .timeout(const Duration(seconds: 12))
        as Map,
  );
}

/// Published catalog, cached independently of private household state.
/// Full snapshots support offline plans/costs; catalog browsing is server-paged.
class RecipeRepository extends ChangeNotifier {
  RecipeRepository({this.source, this.cache});
  RecipeRepository.memory(Iterable<Recipe> recipes)
    : source = null,
      cache = null,
      _initialized = true {
    _all = List.unmodifiable(recipes);
    _known = {for (final r in _all) r.id: r};
  }
  final RecipeSource? source;
  final RecipeCache? cache;
  List<Recipe> _all = const [];
  Map<String, Recipe> _known = {};
  List<Recipe> get all => _all;
  Iterable<Recipe> get known => _known.values;
  Recipe? byId(String id) => _known[id];
  List<Recipe> forSlot(MealSlot slot) =>
      _all.where((r) => r.slot == slot).toList();
  bool _initialized = false, _disposed = false;
  bool loading = false, offline = false;
  Object? error;
  int revision = 0;
  Future<void>? _initializing, _refreshing;
  Future<void> initialize() {
    if (_initialized) return Future.value();
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    loading = true;
    _emit();
    try {
      final encoded = await cache?.read();
      if (encoded != null) {
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;
        if (decoded['schema_version'] != 1) {
          throw const FormatException('Unknown recipe cache');
        }
        final active = _decode(decoded['recipes'] as List);
        final retained = _decode(decoded['retained'] as List? ?? []);
        _all = active;
        _known = {
          for (final r in [...retained, ...active]) r.id: r,
        };
        offline = true;
        revision++;
      }
    } catch (_) {
      // Corrupt/incompatible caches are never silently substituted with fixtures.
    }
    _initialized = true;
    if (_all.isNotEmpty) {
      loading = false;
      _emit();
      unawaited(refresh());
    } else {
      await refresh();
    }
  }

  List<Recipe> _decode(List rows) {
    final recipes = [
      for (final raw in rows)
        Recipe.fromJson(
          Map<String, dynamic>.from(raw as Map),
          imageBaseUrl: source?.imageBaseUrl ?? '',
        ),
    ];
    if (recipes.map((r) => r.id).toSet().length != recipes.length) {
      throw const FormatException('Duplicate recipe IDs');
    }
    return List.unmodifiable(recipes);
  }

  Future<void> refresh() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  Future<void> _refresh() async {
    if (source == null || _disposed) {
      loading = false;
      _emit();
      return;
    }
    loading = true;
    _emit();
    try {
      final next = _decode(await source!.snapshot());
      if (_disposed) return;
      _all = next;
      // Previously downloaded recipes still resolve in existing saved plans.
      _known = {..._known, for (final r in next) r.id: r};
      offline = false;
      error = null;
      revision++;
      try {
        await cache?.write(
          jsonEncode({
            'schema_version': 1,
            'recipes': next.map((r) => r.toJson()).toList(),
            'retained': _known.values
                .where((r) => !next.any((n) => n.id == r.id))
                .map((r) => r.toJson())
                .toList(),
          }),
        );
      } catch (_) {
        // A full disk must not discard a successful server response.
      }
    } catch (failure) {
      if (_disposed) return;
      error = failure;
      offline = true;
    } finally {
      loading = false;
      _emit();
    }
  }

  Future<RecipePage> search({
    required List<Recipe> eligible,
    String query = '',
    String language = 'es',
    MealSlot? slot,
    int page = 0,
    int pageSize = 6,
  }) async {
    if (page < 0 || pageSize < 1 || pageSize > 100) {
      throw ArgumentError('Invalid recipe page');
    }
    if (source != null && !offline) {
      try {
        final result = await source!.search(
          orderedIds: eligible.map((r) => r.id).toList(),
          query: query.trim(),
          language: language,
          slot: slot,
          offset: page * pageSize,
          limit: pageSize,
        );
        final recipes = _decode(result['recipes'] as List);
        // The caller has already applied preferences and portion sizes.
        final portions = {for (final r in eligible) r.id: r.servings};
        if (recipes.any((r) => !portions.containsKey(r.id))) {
          throw const FormatException('Unexpected recipe');
        }
        return RecipePage([
          for (final r in recipes) r.withServings(portions[r.id]!),
        ], result['total'] as int);
      } catch (_) {
        // A failed page request uses the last actual catalog, never fake content.
      }
    }
    final text = query.trim().toLowerCase();
    final filtered = eligible
        .where(
          (r) =>
              (slot == null || r.slot == slot) &&
              r.contentFor(language).title.toLowerCase().contains(text),
        )
        .toList();
    return RecipePage(
      filtered.skip(page * pageSize).take(pageSize).toList(),
      filtered.length,
      offline: source != null,
    );
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
