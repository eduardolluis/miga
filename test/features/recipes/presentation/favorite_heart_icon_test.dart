import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/recipes/presentation/widgets/favorite_heart_icon.dart';

void main() {
  testWidgets('Favorite heart becomes red with an animated transition', (
    tester,
  ) async {
    Widget frame(bool favorite) => MaterialApp(
      home: Scaffold(
        body: FavoriteHeartIcon(
          favorite: favorite,
          inactiveColor: Colors.white,
        ),
      ),
    );
    await tester.pumpWidget(frame(false));
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

    await tester.pumpWidget(frame(true));
    await tester.pumpAndSettle();
    final heart = tester.widget<Icon>(find.byIcon(Icons.favorite_rounded));
    expect(heart.color, const Color(0xFFE53935));
  });
}
