import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/home/presentation/widgets/home_dashboard_quick_actions.dart';
import 'package:miga/l10n/app_localizations.dart';

Widget frame({
  required List<String> opened,
  String language = 'en',
  int remaining = 3,
  bool isPro = false,
  bool busy = false,
}) => MaterialApp(
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: HomeDashboardQuickActions(
    onCookWithPantry: () => opened.add('pantry'),
    onFindCheaper: () => opened.add('cheaper'),
    onSurprise: () => opened.add('surprise'),
    onGenerateWeek: () => opened.add('generate'),
    surpriseRemaining: remaining,
    surpriseBusy: busy,
    isPro: isPro,
  ))),
);

void main() {
  testWidgets('Four useful actions, not duplicate navigation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final opened = <String>[];
    await tester.pumpWidget(frame(opened: opened));
    for (final id in ['pantry', 'cheaper', 'surprise', 'generate']) {
      final finder = find.byKey(ValueKey('home-quick-$id'));
      expect(finder, findsOneWidget);
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();
    }
    expect(opened, ['pantry', 'cheaper', 'surprise', 'generate']);
    expect(find.text('3 of 3 free uses left'), findsOneWidget);
    expect(find.text('Grocery list'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Three free uses then Pro; subscribers are unlimited',
      (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(frame(opened: opened, remaining: 0));
    expect(find.text('0 of 3 free uses left'), findsOneWidget);
    expect(find.text('PRO'), findsNWidgets(3));
    await tester.pumpWidget(frame(opened: opened, remaining: 0, isPro: true));
    expect(find.text('Unlimited'), findsOneWidget);
    expect(find.text('PRO'), findsNothing);
  });

  testWidgets('Busy Surprise cannot be tapped twice', (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(frame(opened: opened, busy: true));
    await tester.tap(find.byKey(const ValueKey('home-quick-surprise')));
    await tester.pump();
    expect(opened, isEmpty);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Spanish labels match actions', (tester) async {
    await tester.pumpWidget(frame(opened: [], language: 'es'));
    expect(find.text('Accesos rápidos'), findsOneWidget);
    expect(find.text('¿Qué puedo cocinar?'), findsOneWidget);
    expect(find.text('Sorpréndeme'), findsOneWidget);
    expect(find.text('3 de 3 usos gratis'), findsOneWidget);
  });
}
