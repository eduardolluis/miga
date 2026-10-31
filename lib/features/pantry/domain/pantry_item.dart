import 'package:miga/features/budget/domain/recipe_amount.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';

class PantryItem {
  const PantryItem(this.ingredient, this.amount, this.unit);
  final RecipeIngredient ingredient;
  final double amount;
  final CostUnit unit;

  Map<String, Object> toJson() => {
    'ingredient': ingredient.name,
    'amount': amount,
    'unit': unit.name,
  };
  static PantryItem? fromJson(Map<String, dynamic> json) {
    final ingredients = RecipeIngredient.values.where(
      (i) => i.name == json['ingredient'],
    );
    final units = CostUnit.values.where((u) => u.name == json['unit']);
    final amount = (json['amount'] as num?)?.toDouble();
    if (ingredients.isEmpty ||
        units.isEmpty ||
        amount == null ||
        !amount.isFinite ||
        amount <= 0) {
      return null;
    }
    return PantryItem(ingredients.first, amount, units.first);
  }
}
