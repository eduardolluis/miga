import 'package:miga/core/region/supported_regions.dart';

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
      SupportedRegions.format(currency, value, compact: true);
}
