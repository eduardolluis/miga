import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/recipes/data/recipe_catalog.dart';
import 'package:miga/features/recipes/data/recipe_photo_catalog.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_image.dart';

void main() {
  test(
    'Every catalog recipe has its own full-resolution offline photo',
    () async {
      expect(RecipeCatalog.all.length, 54);
      expect(RecipePhotoCatalog.images.length, 54);
      final assets = <String>{};
      for (final recipe in RecipeCatalog.all) {
        final photo = RecipePhotoCatalog.images[recipe.imageIndex]!;
        expect(assets.add(photo.asset), isTrue, reason: recipe.id);
        expect(photo.width, greaterThanOrEqualTo(1400), reason: recipe.id);
        expect(photo.height, greaterThanOrEqualTo(1024), reason: recipe.id);
        final bytes = await File(photo.asset).readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, photo.width, reason: recipe.id);
        expect(frame.image.height, photo.height, reason: recipe.id);
        frame.image.dispose();
        codec.dispose();
      }
    },
  );

  testWidgets('Portrait cards decode enough pixels for the physical height', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1170, 2532);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 180,
              height: 240,
              child: RecipeImage(index: 42),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image));
    final resized = image.image as ResizeImage;
    final photo = RecipePhotoCatalog.images[42]!;
    expect(
      resized.width,
      greaterThanOrEqualTo((240 * 3 * photo.aspectRatio).ceil()),
    );
    expect(resized.width, lessThanOrEqualTo(photo.width));
    expect(tester.takeException(), isNull);
  });
}
