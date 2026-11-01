import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miga/features/home/application/home_controller.dart';
import 'package:miga/features/home/data/local_home_details_store.dart';
import 'package:miga/features/home/domain/home_details.dart';
import 'package:miga/features/meal_plan/data/local_meal_plan_store.dart';

class _DelayedStore extends LocalHomeDetailsStore {
  _DelayedStore(super.userId);

  final gate = Completer<void>();
  bool fail = false;

  @override
  Future<void> save(HomeDetails details) async {
    await gate.future;
    if (fail) throw StateError('Simulated offline storage failure');
    await super.save(details);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Heart changes immediately without setting global saving mode', () async {
    SharedPreferences.setMockInitialValues({});
    final store = _DelayedStore('favorite-fast');
    final controller = HomeController(
      today: DateTime(2026, 10, 31),
      planStore: LocalMealPlanStore('favorite-fast'),
      detailsStore: store,
    );
    addTearDown(controller.dispose);
    await controller.load();
    final pending = controller.toggleFavorite('roasted-vegetable-quinoa');

    expect(controller.details.favorites, contains('roasted-vegetable-quinoa'));
    expect(controller.saving, false);
    expect(controller.favoriteSaving, true);
    expect(controller.canEdit, true);

    store.gate.complete();
    expect(await pending, true);
    expect(controller.favoriteSaving, false);
    final persisted = await store.load();
    expect(persisted.favorites, contains('roasted-vegetable-quinoa'));
  });

  test('Failed favorite write restores the previous heart state', () async {
    SharedPreferences.setMockInitialValues({});
    final store = _DelayedStore('favorite-failure')..fail = true;
    final controller = HomeController(
      today: DateTime(2026, 10, 31),
      planStore: LocalMealPlanStore('favorite-failure'),
      detailsStore: store,
    );
    addTearDown(controller.dispose);
    await controller.load();

    final pending = controller.toggleFavorite('banana-oats');
    expect(controller.details.favorites, contains('banana-oats'));
    store.gate.complete();
    expect(await pending, false);
    expect(controller.details.favorites, isNot(contains('banana-oats')));
    expect(controller.favoriteSaving, false);
  });

  test('Rapid taps stay ordered and finish at the latest heart state', () async {
    SharedPreferences.setMockInitialValues({});
    final store = _DelayedStore('favorite-queue');
    final controller = HomeController(
      today: DateTime(2026, 10, 31),
      planStore: LocalMealPlanStore('favorite-queue'),
      detailsStore: store,
    );
    addTearDown(controller.dispose);
    await controller.load();

    final first = controller.toggleFavorite('banana-oats');
    final second = controller.toggleFavorite('banana-oats');
    expect(controller.details.favorites, isNot(contains('banana-oats')));
    store.gate.complete();
    expect(await first, true);
    expect(await second, true);
    expect((await store.load()).favorites, isNot(contains('banana-oats')));
  });
}
