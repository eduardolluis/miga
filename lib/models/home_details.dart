class WeeklyBudget {
  const WeeklyBudget({
    required this.limit,
    required this.spent,
    required this.currency,
  });

  final double limit;
  final double spent;
  final String currency;

  Map<String, Object> toJson() => {
    'limit': limit,
    'spent': spent,
    'currency': currency,
  };

  factory WeeklyBudget.fromJson(Map<String, dynamic> json) => WeeklyBudget(
    limit: (json['limit'] as num).toDouble(),
    spent: (json['spent'] as num).toDouble(),
    currency: json['currency'] as String,
  );

  String format(double value) =>
      '${currency == 'DOP' ? 'RD\$' : '\$'}${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)}';
}

class GroceryItem {
  const GroceryItem(this.name, {this.checked = false});

  final String name;
  final bool checked;

  Map<String, Object> toJson() => {'name': name, 'checked': checked};

  factory GroceryItem.fromJson(Map<String, dynamic> json) =>
      GroceryItem(json['name'] as String, checked: json['checked'] as bool);
}

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
