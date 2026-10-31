import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/home/presentation/widgets/home_header.dart';
import 'package:miga/features/home/presentation/widgets/home_week.dart';
import 'package:miga/l10n/app_localizations.dart';

Widget frame(Widget child, {double scale = 1}) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: SingleChildScrollView(child: child),
    ),
  ),
);

void main() {
  for (final hour in [0, 4, 5, 12, 18, 20, 21, 23]) {
    testWidgets('Greeting at $hour uses the correct time of day', (
      tester,
    ) async {
      await tester.pumpWidget(
        frame(
          HomeHeader(
            onProfile: () {},
            now: DateTime(2026, 10, 31, hour),
            name: null,
          ),
        ),
      );
      final expected = hour < 5 || hour >= 21
          ? 'Good night.'
          : hour < 12
          ? 'Good morning.'
          : hour < 18
          ? 'Good afternoon.'
          : 'Good evening.';
      expect(find.text(expected), findsOneWidget);
    });
  }

  testWidgets('Profile initial keeps a circular button at larger text sizes', (
    tester,
  ) async {
    await tester.pumpWidget(
      frame(
        HomeHeader(
          onProfile: () {},
          now: DateTime(2026, 10, 31, 21),
          name: 'Eduardo',
        ),
        scale: 2,
      ),
    );
    final avatar = find.byKey(const ValueKey('home-profile-avatar'));
    expect(tester.getSize(avatar), const Size.square(52));
    final surface = find
        .descendant(of: avatar, matching: find.byType(Material))
        .first;
    expect(tester.getSize(surface), const Size.square(52));
    expect(tester.widget<Material>(surface).shape, isA<CircleBorder>());
    expect(find.text('E'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    for (final day in [26, 30, 31, 32]) {
      testWidgets(
        'Selected date $day is visible without swiping at scale $scale',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(360, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final date = DateTime(2026, 10, day);
          await tester.pumpWidget(
            frame(
              HomeWeek(
                today: date,
                selectedDate: date,
                onSelected: (_) {},
                hasMeals: (_) => false,
                meal: null,
                slotLabel: 'Dinner',
                onEditMeal: () {},
              ),
              scale: scale,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(ValueKey('home-day-${date.weekday}')).hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
