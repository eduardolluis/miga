import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/recipes/domain/recipe.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_nutrition_panel.dart';
import 'package:miga/l10n/app_localizations.dart';

const _nutrition = RecipeNutrition(
  calories: 420,
  proteinGrams: 14,
  carbsGrams: 58,
);

Widget _app({
  RecipeNutrition? nutrition = _nutrition,
  int servings = 2,
  String language = 'en',
  double textScale = 1,
}) => MaterialApp(
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    backgroundColor: AppColors.cream,
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: RecipeNutritionPanel(nutrition: nutrition, servings: servings),
    ),
  ),
);

String _value(WidgetTester tester, String key) {
  final text = tester.widget<Text>(find.byKey(ValueKey(key)));
  return text.data ?? text.textSpan!.toPlainText();
}

void main() {
  testWidgets('Switching basis shows one summary and scales all totals', (
    tester,
  ) async {
    await tester.pumpWidget(_app(servings: 3));
    expect(_value(tester, 'nutrition-calories'), '420 kcal');
    expect(_value(tester, 'nutrition-protein'), '14 g');
    expect(_value(tester, 'nutrition-carbs'), '58 g');

    await tester.tap(find.byKey(const ValueKey('nutrition-whole-recipe')));
    await tester.pumpAndSettle();
    expect(_value(tester, 'nutrition-calories'), '1260 kcal');
    expect(_value(tester, 'nutrition-protein'), '42 g');
    expect(_value(tester, 'nutrition-carbs'), '174 g');

    await tester.pumpWidget(_app(servings: 4));
    expect(_value(tester, 'nutrition-calories'), '1680 kcal');
    expect(_value(tester, 'nutrition-protein'), '56 g');
    expect(_value(tester, 'nutrition-carbs'), '232 g');

    await tester.tap(find.byKey(const ValueKey('nutrition-per-serving')));
    await tester.pumpAndSettle();
    expect(_value(tester, 'nutrition-calories'), '420 kcal');
    expect(find.byKey(const ValueKey('nutrition-calories')), findsOneWidget);
  });

  testWidgets('One serving has no duplicate basis and never keeps old totals', (
    tester,
  ) async {
    await tester.pumpWidget(_app(servings: 4));
    await tester.tap(find.byKey(const ValueKey('nutrition-whole-recipe')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(servings: 1));
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Per serving'), findsOneWidget);
    expect(_value(tester, 'nutrition-calories'), '420 kcal');
    expect(_value(tester, 'nutrition-protein'), '14 g');
    expect(_value(tester, 'nutrition-carbs'), '58 g');
  });

  testWidgets('Missing nutrition never displays made-up values', (
    tester,
  ) async {
    await tester.pumpWidget(_app(nutrition: null));
    expect(find.text('Nutrition information unavailable.'), findsOneWidget);
    expect(find.byKey(const ValueKey('nutrition-calories')), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  for (final language in ['en', 'es']) {
    testWidgets(
      'Nutrition stays readable at 320 px and large text in $language',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_app(language: language, textScale: 2));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('nutrition-whole-recipe')));
        await tester.pumpAndSettle();
        expect(_value(tester, 'nutrition-calories'), '840 kcal');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
