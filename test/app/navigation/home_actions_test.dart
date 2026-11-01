import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miga/app/navigation/app_shell.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/groceries/presentation/groceries_tab_page.dart';
import 'package:miga/features/home/data/local_home_details_store.dart';
import 'package:miga/features/home/domain/home_details.dart';
import 'package:miga/features/notifications/presentation/notifications_page.dart';
import 'package:miga/l10n/app_localizations.dart';

Widget frame() => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: AppShell(today: DateTime(2026, 10, 31)),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('The bell opens Notifications, then a reminder opens Groceries', (
    tester,
  ) async {
    await LocalHomeDetailsStore('guest')
        .save(const HomeDetails(groceries: [GroceryItem('Eggs')]));
    await tester.pumpWidget(frame());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-notifications')));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsPage), findsOneWidget);
    expect(find.byType(GroceriesTabPage), findsNothing);
    await tester.tap(find.text('Grocery list'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsPage), findsNothing);
    expect(find.byType(GroceriesTabPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Notifications has an empty state instead of invented alerts', (
    tester,
  ) async {
    await tester.pumpWidget(frame());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-notifications')));
    await tester.pumpAndSettle();
    expect(find.text('You’re all caught up'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Empty pantry uses the Miga sheet and can be dismissed', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(frame());
    await tester.pumpAndSettle();
    final pantry = find.byKey(const ValueKey('home-quick-pantry'));
    await tester.scrollUntilVisible(
      pantry,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('home-dashboard')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(pantry);
    await tester.pumpAndSettle();
    expect(find.text('What’s in your kitchen?'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('What’s in your kitchen?'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
