import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miga/app/navigation/app_shell.dart';
import 'package:miga/features/groceries/presentation/widgets/grocery_pro_actions.dart';
import 'package:miga/features/groceries/presentation/sheets/grocery_list_sheet.dart';
import 'package:miga/features/pro/presentation/pro_page.dart';
import 'package:miga/l10n/app_localizations.dart';

Widget app(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  for (final action in ['generate', 'compare']) {
    testWidgets(
      'Groceries shows $action outside the editor and gates Free users',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(app(AppShell(today: DateTime(2026, 10, 31))));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Groceries'));
        await tester.pumpAndSettle();
        expect(find.text('PRO'), findsNWidgets(2));
        await tester.tap(find.byKey(ValueKey('grocery-pro-$action')));
        await tester.pumpAndSettle();
        expect(find.byType(ProPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('Editor gates $action before invoking any premium callback', (
      tester,
    ) async {
      var upgrades = 0, generated = 0;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              child: const Text('Open'),
              onPressed: () => showGroceryList(
                context,
                [],
                onGenerateFromPlan: (items) {
                  generated++;
                  return items;
                },
                onUpgrade: () => upgrades++,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('grocery-pro-$action')));
      await tester.pumpAndSettle();
      expect(upgrades, 1);
      expect(generated, 0);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Premium actions show a loader and cannot double submit', (
    tester,
  ) async {
    final request = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      app(
        GroceryProActions(
          isPro: true,
          onGenerate: () {
            calls++;
            return request.future;
          },
          onCompare: () async {
            calls++;
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('grocery-pro-generate')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('grocery-pro-compare')));
    await tester.pump();
    expect(calls, 1);
    request.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
