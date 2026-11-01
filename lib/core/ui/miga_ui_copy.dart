import 'package:flutter/widgets.dart';

/// Small editorial UI copy for the refreshed Home/Recipes experience.
/// Strings are paired for the two supported languages. Existing domain
/// translations continue to live in l10n/*.arb.
abstract final class MigaUiCopy {
  static bool isSpanish(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'es';

  static String choose(BuildContext context, String es, String en) =>
      isSpanish(context) ? es : en;

  static String getMore(BuildContext context) =>
      choose(context, 'Ver más recetas', 'See all recipes');
  static String budgetSubtitle(BuildContext context) => choose(
    context,
    'Ideas ordenadas según tu presupuesto. Los precios son estimados.',
    'Ideas ranked by your budget. Prices are estimates.',
  );
  static String hero(BuildContext context) =>
      choose(context, 'Planifica,\ncocina y\nahorra.', 'Plan,\ncook &\nsave.');
  static String today(BuildContext context) => choose(context, 'Hoy', 'Today');
  static String ingredientCost(BuildContext context) =>
      choose(context, 'Costo de ingredientes', 'Ingredient cost');
  static String incompletePrices(BuildContext context, int known, int total) =>
      choose(context, '$known/$total precios', '$known/$total prices');
  static String withinBudget(BuildContext context) =>
      choose(context, 'Dentro de tu presupuesto', 'Within budget');
  static String filters(BuildContext context) =>
      choose(context, 'Filtros', 'Filters');
  static String sort(BuildContext context) =>
      choose(context, 'Ordenar', 'Sort');
  static String recommended(BuildContext context) =>
      choose(context, 'Recomendadas', 'Recommended');
  static String quickest(BuildContext context) =>
      choose(context, 'Más rápidas', 'Quickest');
  static String newest(BuildContext context) =>
      choose(context, 'Más nuevas', 'Newest');
  static String totalRecipes(BuildContext context, int count) => choose(
    context,
    '$count ${count == 1 ? 'receta' : 'recetas'}',
    '$count ${count == 1 ? 'recipe' : 'recipes'}',
  );
  static String shopping(BuildContext context) =>
      choose(context, 'Compras', 'Groceries');
  static String openShopping(BuildContext context) =>
      choose(context, 'Editar lista de compras', 'Edit grocery list');
  static String budgetUnknown(BuildContext context) => choose(
    context,
    'Revisa los precios para saber si cabe en tu presupuesto.',
    'Check missing prices to know if it fits your budget.',
  );
  static String neededToCook(BuildContext context) => choose(
    context,
    'Costo estimado de los ingredientes usados, no de paquetes completos.',
    'Estimated ingredient amounts used, not full store packages.',
  );
}
