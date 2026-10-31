import 'package:miga/features/budget/domain/weekly_budget.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';

class HomeDetails {
  const HomeDetails({this.budgets = const {}, this.groceries = const []});

  final Map<String, WeeklyBudget> budgets;
  final List<GroceryItem> groceries;

  HomeDetails withBudget(String week, WeeklyBudget budget) =>
      HomeDetails(budgets: {...budgets, week: budget}, groceries: groceries);

  HomeDetails withGroceries(List<GroceryItem> items) =>
      HomeDetails(budgets: budgets, groceries: items);

  Map<String, Object> toJson() => {
    'budgets': budgets.map((key, value) => MapEntry(key, value.toJson())),
    'groceries': groceries.map((item) => item.toJson()).toList(),
  };

  factory HomeDetails.fromJson(Map<String, dynamic> json) => HomeDetails(
    budgets: (json['budgets'] as Map<String, dynamic>).map(
      (key, value) =>
          MapEntry(key, WeeklyBudget.fromJson(value as Map<String, dynamic>)),
    ),
    groceries: (json['groceries'] as List<dynamic>)
        .map((item) => GroceryItem.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}
