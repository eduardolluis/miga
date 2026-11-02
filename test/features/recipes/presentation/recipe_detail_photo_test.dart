import 'dart:io';
import 'dart:ui' as ui;

import '../../../support/recipe_catalog.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_detail_photo.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_image.dart';

void main() {
  for (final index in [0, 49, 50]) {
    testWidgets(
      'Detail photo $index uses its natural aspect ratio without cropping',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 850);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: RecipeDetailPhoto(photo: RecipeCatalog.all[index].photo),
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          final photo = await File(
            'supabase/catalog/photos/${RecipeCatalog.all[index].id}.jpg',
          ).readAsBytes();
          final codec = await ui.instantiateImageCodec(photo);
          final frame = await codec.getNextFrame();
          frame.image.dispose();
          codec.dispose();
          // Network images are not a dependency of the aspect-ratio test.
          // A missing remote response is handled by RecipeImage.errorBuilder.
        });
        await tester.pumpAndSettle();
        final image = tester.widget<RecipeImage>(find.byType(RecipeImage));
        expect(image.fit, BoxFit.contain);
        final size = tester.getSize(
          find.byKey(const ValueKey('recipe-detail-photo-frame')),
        );
        expect(size.width, 390);
        expect(
          size.height,
          closeTo(390 / RecipeCatalog.all[index].photo.aspectRatio, 1),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Detail photo responds when a different recipe is opened', (
    tester,
  ) async {
    Widget frame(int index) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: RecipeDetailPhoto(photo: RecipeCatalog.all[index].photo),
        ),
      ),
    );
    await tester.pumpWidget(frame(49));
    await tester.pumpAndSettle();
    await tester.pumpWidget(frame(50));
    await tester.pumpAndSettle();
    expect(
      tester.widget<RecipeImage>(find.byType(RecipeImage)).photo.path,
      RecipeCatalog.all[50].photo.path,
    );
    expect(tester.takeException(), isNull);
  });
}
