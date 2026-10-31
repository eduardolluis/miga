import 'package:miga/features/home/domain/home_details.dart';

abstract interface class HomeDetailsStore {
  Future<HomeDetails> load();
  Future<void> save(HomeDetails details);
}

/// Implemented when plans and household data can be committed together.
abstract interface class HouseholdStateStore {
  Future<(Map<String, String>, HomeDetails)> loadState();
  Future<void> saveState(Map<String, String> meals, HomeDetails details);
}
