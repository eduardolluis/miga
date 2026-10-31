import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:miga/app/navigation/app_shell.dart';
import 'package:miga/features/auth/domain/auth_service.dart';
import 'package:miga/features/home/data/local_home_details_store.dart';
import 'package:miga/features/home/presentation/widgets/home_quick_actions.dart';
import 'package:miga/features/home/presentation/widgets/meal_hero_card.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/profile/presentation/profile_page.dart';
import 'package:miga/features/meal_plan/data/local_meal_plan_store.dart';
import 'package:miga/features/meal_plan/domain/meal_plan_store.dart';
import 'package:miga/l10n/app_localizations.dart';
import 'package:miga/features/stores/data/nearby_stores.dart';

import '../../support/fake_auth_service.dart';

final _today = DateTime(2026, 10, 30, 13);

Widget appShellTestApp({
  Locale locale = const Locale('es'),
  double scale = 1,
  MealPlanStore? store,
  DateTime? now,
  AuthService? authService,
  Future<bool> Function(String)? openMaps,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: ThemeData(useMaterial3: true),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: AppShell(
    today: now ?? _today,
    planStore: store,
    authService: authService,
    openNearbyStores: openMaps ?? NearbyStores.open,
  ),
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

  for (final language in ['en', 'es']) {
    testWidgets('Pro opens voluntarily from home and profile in $language', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        appShellTestApp(locale: Locale(language), scale: 2),
      );
      await tester.pumpAndSettle();
      final discover = language == 'en'
          ? 'Discover Miga Pro'
          : 'Descubre Miga Pro';
      final continueFree = language == 'en'
          ? 'Keep using Miga Free'
          : 'Seguir usando Miga Gratis';
      final comingSoon = language == 'en'
          ? 'Coming soon · Features in development'
          : 'Próximamente · Funciones en desarrollo';
      expect(find.text(comingSoon), findsNothing);
      await reveal(tester, find.text(discover));
      await tester.tap(find.text(discover));
      await tester.pumpAndSettle();
      await reveal(tester, find.text(comingSoon));
      expect(find.text(comingSoon), findsOneWidget);
      await reveal(tester, find.text(continueFree));
      await tester.tap(find.text(continueFree));
      await tester.pumpAndSettle();
      expect(find.text(continueFree), findsNothing);
      await tester.tap(find.text(language == 'en' ? 'Profile' : 'Perfil'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text(discover));
      await tester.tap(find.text(discover));
      await tester.pumpAndSettle();
      expect(find.text('Miga Pro'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Carousel swipes between distinct dishes, never the budget', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(appShellTestApp());
    await tester.pumpAndSettle();
    expect(find.text('Para tu almuerzo'), findsOneWidget);
    expect(find.text('Salmón al limón y hierbas'), findsOneWidget);
    expect(
      tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .viewportFraction,
      1,
    );
    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(
      find.text('Pollo con arroz y vegetales').hitTestable(),
      findsOneWidget,
    );
    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(
      find.text('Ensalada de garbanzos y aguacate').hitTestable(),
      findsOneWidget,
    );
    expect(find.text('Presupuesto semanal').hitTestable(), findsNothing);
    final pages = tester.widget<PageView>(find.byType(PageView)).controller!;
    pages.jumpToPage(pages.initialPage + 2);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(
      find.text('Salmón al limón y hierbas').hitTestable(),
      findsOneWidget,
    );
    expect(find.text('1 de 3 recetas'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(320, 0));
    await tester.pumpAndSettle();
    expect(find.text('3 de 3 recetas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final entry in [
    (8, 'Para tu desayuno', 'Avena con banana y canela'),
    (13, 'Para tu almuerzo', 'Salmón al limón y hierbas'),
    (20, 'Para tu cena', 'Pasta con tomate y albahaca'),
  ]) {
    testWidgets('Home selects recipes for local hour ${entry.$1}', (
      tester,
    ) async {
      await tester.pumpWidget(
        appShellTestApp(now: DateTime(2026, 10, 30, entry.$1)),
      );
      await tester.pumpAndSettle();
      expect(find.text(entry.$2), findsOneWidget);
      expect(find.text(entry.$3), findsOneWidget);
      for (var swipe = 0; swipe < 6; swipe++) {
        final card = tester.widget<MealHeroCard>(
          find.byType(MealHeroCard).hitTestable(),
        );
        expect(
          card.recipe.slot,
          MealSlot.forTime(DateTime(2026, 10, 30, entry.$1)),
        );
        await tester.drag(find.byType(PageView), const Offset(-700, 0));
        await tester.pumpAndSettle();
      }
      expect(find.text(entry.$3), findsOneWidget);
    });
  }

  testWidgets('Header uses the signed-in person instead of the brand', (
    tester,
  ) async {
    final service = FakeAuthService();
    addTearDown(service.events.close);
    await service.verifyCode('eduardo.delacruz@example.com', '123456');
    await tester.pumpWidget(appShellTestApp(authService: service));
    await tester.pumpAndSettle();
    expect(find.text('Buenas tardes,\nEduardo.'), findsOneWidget);
    expect(find.text('miga'), findsNothing);
  });

  testWidgets(
    'Meal validation, persistence and removal work from the selected day',
    (tester) async {
      await tester.pumpWidget(appShellTestApp());
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Añadir comida'));
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
      await tester.pumpWidget(appShellTestApp());
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Arroz con vegetales'));
      await tester.tap(find.text('Editar comida'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitar comida'));
      await tester.pumpAndSettle();
      expect(await LocalMealPlanStore('guest').load(), isEmpty);
    },
  );

  testWidgets(
    'Day and mealtime selection show the right saved meal and ideas',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await LocalMealPlanStore('guest').save({
        '2026-10-30:lunch': 'Arroz del viernes',
        '2026-10-26:lunch': 'Lentejas del lunes',
        '2026-10-26:dinner': 'Sopa del lunes',
      });
      await tester.pumpWidget(appShellTestApp());
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const ValueKey('home-day-1')));
      await tester.tap(find.byKey(const ValueKey('home-day-1')));
      await tester.pumpAndSettle();
      expect(find.text('Lentejas del lunes'), findsOneWidget);
      await reveal(
        tester,
        find.byTooltip('Cambiar momento del día'),
        delta: -200,
      );
      tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(2);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cambiar momento del día'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cena'));
      await tester.pumpAndSettle();
      expect(find.text('Pasta con tomate y albahaca'), findsOneWidget);
      await reveal(tester, find.text('Sopa del lunes'));
      expect(find.text('Sopa del lunes'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('home-day-1'))).width,
        greaterThanOrEqualTo(62),
      );
    },
  );

  testWidgets(
    'Budget is independent of the recipe carousel and persists spending',
    (tester) async {
      await tester.pumpWidget(appShellTestApp());
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Definir presupuesto'));
      await tester.tap(find.text('Definir presupuesto'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('budget-limit')), '0');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Introduce un importe válido'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('budget-limit')),
        '4000',
      );
      await tester.enterText(
        find.byKey(const ValueKey('budget-spent')),
        '1250,50',
      );
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(find.textContaining('RD\$1250.50'), findsOneWidget);
      final details = await LocalHomeDetailsStore('guest').load();
      expect(details.budgets['2026-10-26']!.limit, 4000);
      expect(details.budgets['2026-10-26']!.spent, 1250.5);
    },
  );

  testWidgets(
    'Lower cards align and grocery checklist saves without duplicates',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(appShellTestApp());
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Lista de compras'));
      final cards = find.descendant(
        of: find.byType(HomeQuickActions),
        matching: find.byType(Material),
      );
      expect(tester.getSize(cards.first), tester.getSize(cards.last));
      await tester.tap(find.text('Lista de compras'));
      await tester.pumpAndSettle();
      for (final name in ['Tomates', 'tomates', 'Pan']) {
        await tester.enterText(find.byType(TextField), name);
        await tester.tap(find.byTooltip('Añadir producto'));
        await tester.pumpAndSettle();
      }
      await tester.scrollUntilVisible(
        find.widgetWithText(CheckboxListTile, 'Tomates'),
        150,
        scrollable: find
            .descendant(
              of: find.byType(DraggableScrollableSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Tomates'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      final items = (await LocalHomeDetailsStore('guest').load()).groceries;
      expect(items.map((item) => item.name), ['Tomates', 'Pan']);
      expect(items.first.checked, isTrue);
      expect(find.text('1 producto pendiente'), findsOneWidget);
    },
  );

  testWidgets(
    'Each recipe opens its own content and can add ingredients and a meal',
    (tester) async {
      await tester.pumpWidget(appShellTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recetas'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Salmón al limón y hierbas'));
      await tester.tap(find.text('Salmón al limón y hierbas'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Añadir ingredientes a la lista'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Añadir ingredientes a la lista'));
      await tester.pumpAndSettle();
      expect((await LocalHomeDetailsStore('guest').load()).groceries.length, 6);
      await tester.scrollUntilVisible(
        find.text('Añadir a mi plan'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Añadir a mi plan'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'Salmón al limón y hierbas',
      );
      expect(await LocalMealPlanStore('guest').load(), isEmpty);
      await tester.tap(find.text('Guardar comida'));
      await tester.pumpAndSettle();
      expect(
        (await LocalMealPlanStore('guest').load())['2026-10-30:lunch'],
        'Salmón al limón y hierbas',
      );
    },
  );

  testWidgets('A breakfast recipe from the catalog is planned as breakfast', (
    tester,
  ) async {
    await tester.pumpWidget(appShellTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recetas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avena con banana y canela'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Añadir a mi plan'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir a mi plan'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(Form), matching: find.text('Desayuno')),
      findsOneWidget,
    );
    await tester.tap(find.text('Guardar comida'));
    await tester.pumpAndSettle();
    expect(
      (await LocalMealPlanStore('guest').load())['2026-10-30:breakfast'],
      'Avena con banana y canela',
    );
  });

  testWidgets('Failed saves leave the plan unchanged and support retry', (
    tester,
  ) async {
    final store = _FailingPlanStore();
    await tester.pumpWidget(appShellTestApp(store: store));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Añadir comida'));
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

  testWidgets('Failed loading disables planning until retry succeeds', (
    tester,
  ) async {
    final store = _FailingPlanStore()..failLoad = true;
    await tester.pumpWidget(appShellTestApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar tu plan.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Ver receta').first,
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
            find.widgetWithText(FilledButton, 'Ver receta').first,
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('Nearby stores opens maps and reports a failed launch', (
    tester,
  ) async {
    String? requestedLanguage;
    await tester.pumpWidget(
      appShellTestApp(
        openMaps: (language) async {
          requestedLanguage = language;
          return false;
        },
      ),
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Tiendas cercanas'));
    await tester.tap(find.text('Tiendas cercanas'));
    await tester.pumpAndSettle();
    expect(requestedLanguage, 'es');
    expect(
      find.text('No pudimos abrir los mapas. Inténtalo de nuevo.'),
      findsOneWidget,
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
          await tester.pumpWidget(
            appShellTestApp(locale: locale, scale: scale),
          );
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
