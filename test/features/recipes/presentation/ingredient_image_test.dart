import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
import 'package:miga/features/recipes/presentation/widgets/ingredient_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('All catalog ingredients have a bundled illustration', () async {
    for (final ingredient in RecipeIngredient.values) {
      final data = await rootBundle.load(IngredientImage.assetFor(ingredient));
      expect(data.lengthInBytes, greaterThan(100),
          reason: 'Missing illustration for ${ingredient.name}');
    }
  });

  testWidgets('Egg is an image, not a generic restaurant icon', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('es'),
      home: Scaffold(body: IngredientImage(ingredient: RecipeIngredient.eggs)),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ingredient-icon-eggs')), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect((image.image as AssetImage).assetName,
        'assets/images/ingredients/eggs.png');
    expect(tester.takeException(), isNull);
  });
}
