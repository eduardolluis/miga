import 'package:flutter_test/flutter_test.dart';
import 'package:miga/core/region/supported_regions.dart';
import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';

void main() {
  test('Every region has a supported currency and distinct ISO country', () {
    final countries = SupportedRegions.all.map((r) => r.countryCode).toList();
    expect(countries.toSet().length, countries.length);
    for (final region in SupportedRegions.all) {
      expect(SupportedRegions.validCurrency(region.currencyCode), isTrue);
    }
  });
  test('Manual amounts show the right currency without implied conversion', () {
    expect(const WeeklyBudget(limit: 100, spent: 0, currency: 'MXN').format(100), 'MX\$100');
    expect(const WeeklyBudget(limit: 100, spent: 0, currency: 'EUR').format(100), '€100');
    expect(const GroceryItem('Bread', currency: 'COP').formatCents(12345), 'COP\$123.45');
  });
}
