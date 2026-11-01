import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:miga/features/home/domain/home_details.dart';
import 'package:miga/features/home/domain/home_details_store.dart';
import 'package:miga/features/home/data/local_home_details_store.dart';
import 'package:miga/features/meal_plan/domain/meal_plan_store.dart';
import 'package:miga/features/meal_plan/data/local_meal_plan_store.dart';

enum SyncStatus { synced, pending, conflict, syncing }

/// An account-scoped durable outbox. A compare-and-swap RPC prevents one
/// device from silently replacing a newer revision from another device.
class CloudSync extends ChangeNotifier {
  CloudSync(this.client, this.userId);
  final SupabaseClient client;
  final String userId;
  SyncStatus status = SyncStatus.pending;
  int remoteGeneration = 0;
  int _consumerGeneration = 0;
  final conflicts = <String>{};
  bool _busy = false, _again = false, _disposed = false;
  Future<bool>? _inFlight;
  Future<void> _localQueue = Future.value();
  String _key(String kind) => 'miga.sync.v1.$userId.$kind';

  Future<Map<String, dynamic>?> _cached(String kind) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key(kind));
    return value == null ? null : jsonDecode(value) as Map<String, dynamic>;
  }

  Future<void> _store(String kind, Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_key(kind), jsonEncode(value))) {
      throw StateError('Local save failed');
    }
  }

  Future<void> _update(
    String kind,
    Map<String, dynamic> Function(Map<String, dynamic>?) change,
  ) {
    final operation = _localQueue.then(
      (_) async => _store(kind, change(await _cached(kind))),
    );
    _localQueue = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<Map<String, dynamic>> read(
    String kind,
    Future<Map<String, dynamic>> Function() legacy,
  ) async {
    final cached = await _cached(kind);
    if (cached != null) return cached['data'] as Map<String, dynamic>;
    final data = await legacy();
    // Imported local data is kept until the server confirms the first write.
    await _update(
      kind,
      (current) =>
          current ??
          {'data': data, 'revision': 0, 'dirty': true, 'generation': 0},
    );
    return (await _cached(kind))!['data'] as Map<String, dynamic>;
  }

  Future<void> write(String kind, Map<String, dynamic> data) async {
    await _update(
      kind,
      (cached) => {
        'data': data,
        'revision': cached?['revision'] ?? 0,
        'dirty': true,
        'generation': ((cached?['generation'] as int?) ?? 0) + 1,
      },
    );
    status = _busy ? SyncStatus.syncing : SyncStatus.pending;
    _notify();
    unawaited(sync());
  }

  Future<Map<String, dynamic>> readState() async {
    final generation = remoteGeneration;
    final state = await read(
      'state',
      () async => {
        'plan': await LocalMealPlanStore(userId).load(),
        'home': (await LocalHomeDetailsStore(userId).load()).toJson(),
      },
    );
    _consumerGeneration = generation;
    return state;
  }

  Future<void> writeState(Map<String, String> meals, HomeDetails details) {
    if (_consumerGeneration != remoteGeneration) {
      throw StateError('Reload newer cloud state before saving');
    }
    return write('state', {'plan': meals, 'home': details.toJson()});
  }

  Future<bool> sync() {
    if (_inFlight != null) {
      _again = true;
      return _inFlight!;
    }
    final task = _synchronize().whenComplete(() => _inFlight = null);
    _inFlight = task;
    return task;
  }

  Future<bool> _synchronize() async {
    if (_busy) {
      _again = true;
      return false;
    }
    if (client.auth.currentUser?.id != userId || _disposed) return false;
    _busy = true;
    var changed = false, failed = false;
    status = SyncStatus.syncing;
    _notify();
    try {
      do {
        _again = false;
        for (final kind in ['state']) {
          if (conflicts.contains(kind)) continue;
          final local = await _cached(kind);
          if (local == null) continue;
          try {
            final remote = await client
                .from('miga_documents')
                .select('data, revision')
                .eq('user_id', userId)
                .eq('kind', kind)
                .maybeSingle()
                .timeout(const Duration(seconds: 8));
            final revision = remote?['revision'] as int? ?? 0;
            final latest = await _cached(kind);
            if (latest == null) continue;
            if (latest['dirty'] == true) {
              // A fresh installation must read the cloud before creating a new
              // empty document. Nonempty local imports require explicit resolution.
              if (revision != latest['revision']) {
                final data = latest['data'] as Map<String, dynamic>;
                final empty =
                    (data['plan'] as Map).isEmpty &&
                    _emptyHome(data['home'] as Map<String, dynamic>);
                if (empty && latest['generation'] == 0 && remote != null) {
                  await _update(kind, (current) {
                    if (current?['generation'] != latest['generation']) {
                      _again = true;
                      return current!;
                    }
                    changed = true;
                    return {
                      'data': remote['data'],
                      'revision': revision,
                      'dirty': false,
                      'generation': 0,
                    };
                  });
                  continue;
                }
                conflicts.add(kind);
                continue;
              }
              final saved = await client
                  .rpc(
                    'miga_put_document',
                    params: {
                      'p_kind': kind,
                      'p_data': latest['data'],
                      'p_revision': revision,
                    },
                  )
                  .timeout(const Duration(seconds: 8));
              await _update(kind, (current) {
                final unchanged =
                    current!['generation'] == latest['generation'];
                if (!unchanged) _again = true;
                return {
                  ...current,
                  'revision': saved as int,
                  'dirty': !unchanged,
                };
              });
            } else if (remote != null &&
                revision > (latest['revision'] as int)) {
              await _update(kind, (current) {
                if (current?['dirty'] == true ||
                    current?['generation'] != latest['generation']) {
                  _again = true;
                  return current!;
                }
                changed = true;
                return {
                  'data': remote['data'],
                  'revision': revision,
                  'dirty': false,
                  'generation': latest['generation'],
                };
              });
            }
          } on PostgrestException catch (error) {
            if (error.code == '40001') {
              conflicts.add(kind);
            } else {
              failed = true;
            }
          } catch (_) {
            failed = true;
          }
        }
      } while (_again &&
          !failed &&
          !_disposed &&
          client.auth.currentUser?.id == userId);
    } finally {
      _busy = false;
      if (changed) remoteGeneration++;
      status = conflicts.isNotEmpty
          ? SyncStatus.conflict
          : failed
          ? SyncStatus.pending
          : SyncStatus.synced;
      _notify();
    }
    return changed;
  }

  bool _emptyHome(Map<String, dynamic> data) =>
      (data['budgets'] as Map? ?? {}).isEmpty &&
      (data['groceries'] as List? ?? []).isEmpty &&
      (data['purchases'] as List? ?? []).isEmpty &&
      (data['pantry'] as List? ?? []).isEmpty &&
      (data['favorites'] as List? ?? []).isEmpty &&
      (data['servings'] as Map? ?? {}).isEmpty &&
      (data['ingredientPrices'] as Map? ?? {}).isEmpty &&
      jsonEncode(data['preferences']) ==
          jsonEncode(const HomeDetails().toJson()['preferences']);

  Future<void> resolve({required bool keepLocal}) async {
    if (_busy) return;
    for (final kind in conflicts.toList()) {
      final local = await _cached(kind);
      final remote = await client
          .from('miga_documents')
          .select('data, revision')
          .eq('user_id', userId)
          .eq('kind', kind)
          .single();
      await _update(
        kind,
        (current) => {
          'data': keepLocal ? current!['data'] : remote['data'],
          'revision': remote['revision'],
          'dirty': keepLocal,
          'generation': (local?['generation'] as int? ?? 0) + 1,
        },
      );
      conflicts.remove(kind);
    }
    await sync();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class SyncedHomeDetailsStore implements HomeDetailsStore, HouseholdStateStore {
  SyncedHomeDetailsStore(this.sync);
  final CloudSync sync;
  @override
  Future<(Map<String, String>, HomeDetails)> loadState() async {
    final state = await sync.readState();
    return (
      (state['plan'] as Map).cast<String, String>(),
      HomeDetails.fromJson(state['home'] as Map<String, dynamic>),
    );
  }

  @override
  Future<HomeDetails> load() async => HomeDetails.fromJson(
    (await sync.readState())['home'] as Map<String, dynamic>,
  );
  @override
  Future<void> save(HomeDetails details) async => sync.writeState(
    ((await sync.readState())['plan'] as Map).cast<String, String>(),
    details,
  );
  @override
  Future<void> saveState(Map<String, String> meals, HomeDetails details) =>
      sync.writeState(meals, details);
}

class SyncedMealPlanStore implements MealPlanStore {
  SyncedMealPlanStore(this.sync);
  final CloudSync sync;
  @override
  Future<Map<String, String>> load() async =>
      ((await sync.readState())['plan'] as Map).cast<String, String>();
  @override
  Future<void> save(Map<String, String> meals) async => sync.writeState(
    meals,
    HomeDetails.fromJson(
      (await sync.readState())['home'] as Map<String, dynamic>,
    ),
  );
}
