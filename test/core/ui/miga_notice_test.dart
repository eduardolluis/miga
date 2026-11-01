import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/core/theme/app_theme.dart';
import 'package:miga/core/ui/miga_notice.dart';

Widget frame({VoidCallback? undo, double textScale = 1}) => MaterialApp(
  theme: AppTheme.household(ThemeData(useMaterial3: true)),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        child: const Text('Save'),
        onPressed: () => showMigaNotice(
          context,
          'Purchase saved',
          action: SnackBarAction(label: 'Undo', onPressed: undo ?? () {}),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('A notice with Undo closes automatically after three seconds', (
    tester,
  ) async {
    await tester.pumpWidget(frame());
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final notice = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(notice.persist, isFalse);
    expect(notice.behavior, SnackBarBehavior.floating);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Purchase saved'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });
  testWidgets('Undo still works before the notice expires', (tester) async {
    var undone = false;
    await tester.pumpWidget(frame(undo: () => undone = true));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, isTrue);
    expect(find.byType(SnackBar), findsNothing);
  });
  testWidgets('A replacement notice does not leave a queue of old messages', (
    tester,
  ) async {
    await tester.pumpWidget(frame());
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });
  testWidgets('Floating notice fits a narrow screen with large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(frame(textScale: 2));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
