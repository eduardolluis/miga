import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/features/recipes/data/recipe_catalog.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_card.dart';
import 'package:miga/features/recipes/presentation/widgets/recipe_image.dart';
import 'package:miga/l10n/app_localizations.dart';

void main() {
  testWidgets('Recipe card uses a full-bleed image with text overlaid', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SizedBox(width: 180, height: 220,
        child: RecipeCard(recipe: RecipeCatalog.all.first, onTap: () {}),
      )),
    ));
    await tester.pumpAndSettle();
    final card = find.byKey(ValueKey('recipe-card-${RecipeCatalog.all.first.id}'));
    expect(card, findsOneWidget);
    expect(find.descendant(of: card, matching: find.byType(RecipeImage)), findsOneWidget);
    expect(find.descendant(of: card, matching: find.byType(Stack)), findsWidgets);
    expect(find.descendant(of: card, matching: find.byType(Text)), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
