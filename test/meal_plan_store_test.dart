import 'package:flutter_test/flutter_test.dart';
import 'package:miga/models/home_details.dart';
import 'package:miga/services/home_details_store.dart';
import 'package:miga/services/meal_plan_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test(
    'Budget history and checked groceries survive a reload per account',
    () async {
      const current = WeeklyBudget(limit: 4000, spent: 1000.5, currency: 'DOP');
      const previous = WeeklyBudget(limit: 3000, spent: 2000, currency: 'DOP');
      const details = HomeDetails(
        budgets: {'2026-10-26': current, '2026-10-19': previous},
        groceries: [GroceryItem('Tomates', checked: true), GroceryItem('Pan')],
      );
      await HomeDetailsStore('first').save(details);
      final restored = await HomeDetailsStore('first').load();
      expect(restored.budgets['2026-10-26']!.spent, 1000.5);
      expect(restored.budgets['2026-10-19']!.limit, 3000);
      expect(restored.groceries.first.checked, isTrue);
      expect(restored.groceries.last.name, 'Pan');
      expect((await HomeDetailsStore('second').load()).budgets, isEmpty);
      expect((await HomeDetailsStore('second').load()).groceries, isEmpty);
    },
  );
}
