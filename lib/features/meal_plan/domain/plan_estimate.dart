class PlanEstimate {
  const PlanEstimate({
    required this.subtotalCents,
    required this.pricedMeals,
    required this.totalMeals,
  });
  final int subtotalCents;
  final int pricedMeals;
  final int totalMeals;
  bool get complete => totalMeals > 0 && pricedMeals == totalMeals;
}
