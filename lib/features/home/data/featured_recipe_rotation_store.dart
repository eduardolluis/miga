import 'package:shared_preferences/shared_preferences.dart';

/// Persists the recommendation cursor, not recipe records. Each fresh launch
/// advances the cursor so rebuilding widgets never reshuffles visible cards.
abstract interface class FeaturedRecipeRotationStore {
  Future<int> advance(String namespace);
}

class LocalFeaturedRecipeRotationStore
    implements FeaturedRecipeRotationStore {
  const LocalFeaturedRecipeRotationStore();

  @override
  Future<int> advance(String namespace) async {
    final preferences = await SharedPreferences.getInstance();
    final key = 'miga.featured.rotation.v1.$namespace';
    final next = ((preferences.getInt(key) ?? -1) + 1) % 1000000;
    if (!await preferences.setInt(key, next)) {
      throw StateError('Unable to persist recipe rotation');
    }
    return next;
  }
}
