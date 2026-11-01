import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/core/ui/miga_skeleton.dart';

void main() {
  testWidgets('Loading blocks taps and preserves mounted content on reload', (
    tester,
  ) async {
    var taps = 0;
    final field = TextEditingController();
    addTearDown(field.dispose);
    Widget frame(bool loading) => MaterialApp(
      home: Scaffold(
        body: SkeletonContent(
          loading: loading,
          skeleton: const SkeletonRows(),
          child: Column(
            children: [
              TextField(controller: field),
              TextButton(onPressed: () => taps++, child: const Text('Action')),
            ],
          ),
        ),
      ),
    );

    await tester.pumpWidget(frame(false));
    await tester.enterText(find.byType(TextField), 'keep my input');
    final state = tester.state(find.byType(TextField));
    await tester.pumpWidget(frame(true));
    await tester.tap(find.text('Action'), warnIfMissed: false);
    expect(taps, 0);
    expect(find.byType(SkeletonRows), findsOneWidget);
    await tester.pumpWidget(frame(false));
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(TextField)), same(state));
    expect(field.text, 'keep my input');
    expect(find.byType(SkeletonRows), findsNothing);
    await tester.tap(find.text('Action'));
    expect(taps, 1);
  });

  testWidgets('Reduced motion renders static placeholders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: SkeletonRows()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonBox), findsNWidgets(9));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('Hidden skeletons stop requesting animation frames', (
    tester,
  ) async {
    Widget frame(bool enabled) => MaterialApp(
      home: TickerMode(
        enabled: enabled,
        child: const Scaffold(body: SkeletonRows()),
      ),
    );
    await tester.pumpWidget(frame(true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(frame(false));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets(
    'Image placeholder leaves when decoded and cached frames skip it',
    (tester) async {
      const content = ColoredBox(color: Colors.green);
      Widget frame(int? imageFrame, {bool cached = false}) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 80,
            child: Builder(
              builder: (context) =>
                  skeletonImageFrame(context, content, imageFrame, cached),
            ),
          ),
        ),
      );
      await tester.pumpWidget(frame(null));
      expect(find.byType(SkeletonBox), findsOneWidget);
      await tester.pumpWidget(frame(0));
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonBox), findsNothing);
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );
      await tester.pumpWidget(frame(0, cached: true));
      expect(find.byType(AnimatedOpacity), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
