import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/recipes/presentation/widgets/favorite_heart_icon.dart';

void main() {
  testWidgets('Favorite heart crossfades/scales without changing its box size', (tester) async {
    Widget icon(bool selected) => MaterialApp(
      home: Scaffold(body: Center(child: FavoriteHeartIcon(favorite: selected, size: 25))),
    );
    await tester.pumpWidget(icon(false));
    expect(tester.getSize(find.byType(FavoriteHeartIcon)), const Size(25, 25));
    await tester.pumpWidget(icon(true));
    final switcher = tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));
    expect(switcher.duration, const Duration(milliseconds: 260));
    await tester.pump(const Duration(milliseconds: 130));
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(tester.getSize(find.byType(FavoriteHeartIcon)), const Size(25, 25));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
  });
}
