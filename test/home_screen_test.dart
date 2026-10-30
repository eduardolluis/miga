import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/l10n/app_localizations.dart';
import 'package:miga/screens/home/home_screen.dart';
import 'package:miga/services/home_details_store.dart';
import 'package:miga/services/meal_plan_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _today = DateTime(2026, 10, 30);

Widget homeApp({
  Locale locale = const Locale('es'),
  double scale = 1,
  MealPlanStore? store,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: ThemeData(useMaterial3: true),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: HomeScreen(today: _today, planStore: store),
);

Future<void> reveal(
  WidgetTester tester,
  Finder finder, {
  double delta = 200,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('First day has honest empty states and one full carousel card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(homeApp());
    await tester.pumpAndSettle();
    expect(find.text('Tu próxima comida,\na tu gusto.'), findsOneWidget);
    expect(find.text('Añadir comida').hitTestable(), findsOneWidget);
    expect(
      tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .viewportFraction,
      1,
    );
    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(find.text('Definir presupuesto').hitTestable(), findsOneWidget);
    expect(find.text('Añadir comida').hitTestable(), findsNothing);
    expect(find.text('RD\$0'), findsNothing);
    expect(find.textContaining('Pro'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Meal validation, saving, restart and removing work', (
    tester,
  ) async {
    await tester.pumpWidget(homeApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir comida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar comida'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe el nombre de tu comida.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField),
      '  Arroz con vegetales  ',
    );
    await tester.tap(find.text('Guardar comida'));
    await tester.pumpAndSettle();
    expect(find.text('Arroz con vegetales'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(homeApp());
    await tester.pumpAndSettle();
    expect(find.text('Arroz con vegetales'), findsOneWidget);
    await tester.tap(find.text('Editar comida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitar comida'));
    await tester.pumpAndSettle();
    expect(find.text('Tu próxima comida,\na tu gusto.'), findsOneWidget);
    expect(await LocalMealPlanStore('guest').load(), isEmpty);
  });

  testWidgets('Selecting a day updates the hero and returns from budget', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await LocalMealPlanStore('guest').save({
      '2026-10-30:lunch': 'Arroz del viernes',
      '2026-10-26:lunch': 'Lentejas del lunes',
      '2026-10-26:dinner': 'Sopa del lunes',
    });
    await tester.pumpWidget(homeApp());
    await tester.pumpAndSettle();
    expect(find.text('Arroz del viernes'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('home-day-1')));
    await tester.tap(find.byKey(const ValueKey('home-day-1')));
    await tester.pumpAndSettle();
    expect(find.text('Lentejas del lunes'), findsOneWidget);
    await reveal(tester, find.widgetWithText(ChoiceChip, 'Cena'), delta: -200);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Cena'));
    await tester.pumpAndSettle();
    expect(find.text('Sopa del lunes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Budget validates amounts and persists recorded spending', (
    tester,
  ) async {
    await tester.pumpWidget(homeApp());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Definir presupuesto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('budget-limit')), '0');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Introduce un importe válido'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('budget-limit')), '4000');
    await tester.enterText(
      find.byKey(const ValueKey('budget-spent')),
      '1250,50',
    );
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(find.text('RD\$1250.50'), findsOneWidget);
    expect(find.text('Dentro de tu presupuesto.'), findsOneWidget);
    final details = await HomeDetailsStore('guest').load();
    expect(details.budgets['2026-10-26']!.limit, 4000);
    expect(details.budgets['2026-10-26']!.spent, 1250.5);
  });

  testWidgets('Grocery list adds, checks and saves items without duplication', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(homeApp());
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Lista de compras'));
    expect(find.text('Lista de compras'), findsOneWidget);
    await tester.tap(find.text('Lista de compras'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tomates');
    await tester.tap(find.byTooltip('Añadir producto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'tomates');
    await tester.tap(find.byTooltip('Añadir producto'));
    await tester.pumpAndSettle();
    expect(find.text('Tomates'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Pan');
    await tester.tap(find.byTooltip('Añadir producto'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Tomates'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    final items = (await HomeDetailsStore('guest').load()).groceries;
    expect(items.map((item) => item.name), ['Tomates', 'Pan']);
    expect(items.first.checked, isTrue);
    expect(find.text('1 producto pendiente'), findsOneWidget);
  });

  testWidgets('Recipes show details and add a meal only after confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(homeApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recetas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver receta'));
    await tester.pumpAndSettle();
    expect(find.text('Ingredientes'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Añadir a mi plan'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Añadir a mi plan'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'Salmón al limón y hierbas',
    );
    expect(await LocalMealPlanStore('guest').load(), isEmpty);
    await tester.tap(find.text('Guardar comida'));
    await tester.pumpAndSettle();
    expect(
      (await LocalMealPlanStore('guest').load())['2026-10-30:lunch'],
      'Salmón al limón y hierbas',
    );
  });

  testWidgets('A failed save can be retried without showing an unsaved meal', (
    tester,
  ) async {
    final store = _FailingPlanStore();
    await tester.pumpWidget(homeApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir comida'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Pasta');
    await tester.tap(find.text('Guardar comida'));
    await tester.pumpAndSettle();
    expect(find.text('Pasta'), findsNothing);
    expect(find.textContaining('No pudimos guardar'), findsOneWidget);
    store.fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Pasta'), findsOneWidget);
  });

  testWidgets('A failed load blocks editing until retry succeeds', (
    tester,
  ) async {
    final store = _FailingPlanStore()..failLoad = true;
    await tester.pumpWidget(homeApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar tu plan.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Añadir comida'),
          )
          .onPressed,
      isNull,
    );
    store.failLoad = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar tu plan.'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Añadir comida'),
          )
          .onPressed,
      isNotNull,
    );
  });

  for (final locale in [const Locale('es'), const Locale('en')]) {
    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
    ]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('Home and tabs fit $size, $locale, text $scale', (
          tester,
        ) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(homeApp(locale: locale, scale: scale));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await reveal(tester, find.byType(PageView));
          tester
              .widget<PageView>(find.byType(PageView))
              .controller!
              .jumpToPage(1);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (final label in [
            'Plan',
            locale.languageCode == 'es' ? 'Recetas' : 'Recipes',
            locale.languageCode == 'es' ? 'Perfil' : 'Profile',
          ]) {
            await tester.tap(find.text(label));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        });
      }
    }
  }
}

class _FailingPlanStore implements MealPlanStore {
  bool fail = true;
  bool failLoad = false;

  @override
  Future<Map<String, String>> load() async {
    if (failLoad) throw StateError('read failed');
    return {};
  }

  @override
  Future<void> save(Map<String, String> meals) async {
    if (fail) throw StateError('write failed');
  }
}
