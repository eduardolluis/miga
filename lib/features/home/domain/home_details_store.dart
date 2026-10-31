import 'package:miga/features/home/domain/home_details.dart';

abstract interface class HomeDetailsStore {
  Future<HomeDetails> load();
  Future<void> save(HomeDetails details);
}
