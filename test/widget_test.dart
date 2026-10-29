import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/app.dart';
import 'package:miga/l10n/app_localizations.dart';
import 'package:miga/screens/auth/auth_screen.dart';
import 'package:miga/screens/onboarding/onboarding_screen.dart';
import 'package:miga/screens/onboarding/onboarding_page.dart';

Widget onboarding({Locale locale = const Locale('es'), double textScale = 1}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B8E72)),
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: const OnboardingScreen(),
  );
}

void main() {
  testWidgets('App opens on the onboarding carousel', (tester) async {
    await tester.pumpWidget(const MigaApp());
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('miga'), findsOneWidget);
    expect(find.text('Good food starts with a good plan.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [const Locale('es'), const Locale('en')]) {
    testWidgets('Carousel navigation and signup in ${locale.languageCode}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final l10n = lookupAppLocalizations(locale);
      await tester.pumpWidget(onboarding(locale: locale));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(PageView), const Offset(-350, 0));
      await tester.pumpAndSettle();
      expect(find.text(l10n.planTitle), findsOneWidget);
      expect(
        tester
            .widget<OnboardingBackground>(find.byType(OnboardingBackground))
            .page
            .imagePath,
        endsWith('meal-planning.png'),
      );

      await tester.tap(find.text(l10n.next));
      await tester.pumpAndSettle();
      expect(find.text(l10n.shoppingTitle), findsOneWidget);
      expect(
        tester
            .widget<OnboardingBackground>(find.byType(OnboardingBackground))
            .page
            .imagePath,
        endsWith('grocery-list.png'),
      );

      await tester.drag(find.byType(PageView), const Offset(350, 0));
      await tester.pumpAndSettle();
      expect(find.text(l10n.planTitle), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(l10n.onboardingStep(1, 4)));
      await tester.pumpAndSettle();
      expect(find.text(l10n.welcomeTitle), findsOneWidget);

      await tester.tap(find.text(l10n.skip));
      await tester.pumpAndSettle();
      expect(find.text(l10n.storesTitle), findsOneWidget);
      expect(
        tester
            .widget<OnboardingBackground>(find.byType(OnboardingBackground))
            .page
            .imagePath,
        endsWith('nearby-stores.png'),
      );
      expect(find.text(l10n.createAccount), findsOneWidget);

      await tester.tap(find.text(l10n.createAccount));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Rapid next taps advance only one slide', (tester) async {
    await tester.pumpWidget(onboarding());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    expect(find.text('Planifica tu semana.'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 1024),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Carousel fits $size with text scale $scale', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(onboarding(textScale: scale));
        await tester.pumpAndSettle();

        for (var page = 1; page <= 4; page++) {
          await tester.tap(find.bySemanticsLabel('Paso $page de 4'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(tester.getSize(find.byType(OnboardingBackground)), size);
        }
        expect(find.text('Crear cuenta').hitTestable(), findsOneWidget);
      });
    }
  }
}
