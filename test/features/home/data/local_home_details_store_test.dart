import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/home/data/local_home_details_store.dart';
import 'package:miga/features/home/domain/home_details.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Budget history and checked groceries survive a reload per account',
    () async {
      const current = WeeklyBudget(limit: 4000, spent: 1000.5, currency: 'DOP');
      const previous = WeeklyBudget(limit: 3000, spent: 2000, currency: 'DOP');
      const details = HomeDetails(
        budgets: {'2026-10-26': current, '2026-10-19': previous},
        groceries: [GroceryItem('Tomates', checked: true), GroceryItem('Pan')],
      );
      await LocalHomeDetailsStore('first').save(details);
      final restored = await LocalHomeDetailsStore('first').load();
      expect(restored.budgets['2026-10-26']!.spent, 1000.5);
      expect(restored.budgets['2026-10-19']!.limit, 3000);
      expect(restored.groceries.first.checked, isTrue);
      expect(restored.groceries.last.name, 'Pan');
      expect((await LocalHomeDetailsStore('second').load()).budgets, isEmpty);
      expect((await LocalHomeDetailsStore('second').load()).groceries, isEmpty);
    },
  );
}
