import '../../support/recipe_catalog.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/app/navigation/app_shell.dart';
import 'package:miga/app/navigation/app_tab.dart';
import 'package:miga/app/navigation/widgets/app_page_skeleton.dart';
import 'package:miga/core/ui/miga_skeleton.dart';
import 'package:miga/features/home/domain/home_details.dart';
import 'package:miga/features/home/domain/home_details_store.dart';
import 'package:miga/features/meal_plan/domain/meal_plan_store.dart';
import 'package:miga/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PendingDetails implements HomeDetailsStore {
  final result = Completer<HomeDetails>();
  @override
  Future<HomeDetails> load() => result.future;
  @override
  Future<void> save(HomeDetails details) async {}
}

class _EmptyPlan implements MealPlanStore {
  @override
  Future<Map<String, String>> load() async => {};
  @override
  Future<void> save(Map<String, String> meals) async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final fail in [false, true]) {
    testWidgets(
      'Tabs show placeholders until data ${fail ? 'fails' : 'loads'}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final details = _PendingDetails();
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AppShell(
              recipeRepository: RecipeCatalog.repository(),
              today: DateTime(2026, 11, 1),
              planStore: _EmptyPlan(),
              detailsStore: details,
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.widget<AppPageSkeleton>(find.byType(AppPageSkeleton)).tab,
          AppTab.home,
        );
        for (final (label, tab) in [
          ('Recetas', AppTab.recipes),
          ('Compras', AppTab.groceries),
          ('Perfil', AppTab.profile),
        ]) {
          await tester.tap(find.text(label).last);
          await tester.pump(const Duration(milliseconds: 250));
          expect(
            tester.widget<AppPageSkeleton>(find.byType(AppPageSkeleton)).tab,
            tab,
          );
        }
        if (fail) {
          details.result.completeError(StateError('offline'));
        } else {
          details.result.complete(const HomeDetails());
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byType(AppPageSkeleton), findsNothing);
        for (final loading in tester.widgetList<SkeletonContent>(
          find.byType(SkeletonContent, skipOffstage: false),
        )) {
          expect(loading.loading, isFalse);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
