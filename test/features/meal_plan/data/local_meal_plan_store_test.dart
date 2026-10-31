import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:miga/features/meal_plan/data/local_meal_plan_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Plans are restored and kept separate between accounts', () async {
    final first = LocalMealPlanStore('first');
    final second = LocalMealPlanStore('second');
    expect(await first.load(), isEmpty);
    await first.save({'2026-10-30:lunch': 'Arroz'});
    await second.save({'2026-10-30:dinner': 'Sopa'});
    expect(await LocalMealPlanStore('first').load(), {
      '2026-10-30:lunch': 'Arroz',
    });
    expect(await second.load(), {'2026-10-30:dinner': 'Sopa'});
  });

  test(
    'Unreadable plans are reported instead of silently overwritten',
    () async {
      SharedPreferences.setMockInitialValues({
        'miga.meals.v1.first': '{broken',
      });
      final store = LocalMealPlanStore('first');
      await expectLater(store.load(), throwsFormatException);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'miga.meals.v1.first',
        ),
        '{broken',
      );
    },
  );
}
