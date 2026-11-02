import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miga/features/home/data/featured_recipe_rotation_store.dart';

void main() {
  test('Rotation advances once per app launch, scoped to the signed-in user', () async {
    SharedPreferences.setMockInitialValues({});
    const store = LocalFeaturedRecipeRotationStore();
    expect(await store.advance('account-a'), 0);
    expect(await store.advance('account-a'), 1);
    expect(await store.advance('account-b'), 0);
    expect(await store.advance('account-a'), 2);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('miga.featured.rotation.v1.account-a'), 2);
  });
}
