import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:miga/features/home/domain/home_details.dart';
import 'package:miga/features/home/domain/home_details_store.dart';

class LocalHomeDetailsStore implements HomeDetailsStore {
  LocalHomeDetailsStore(String userId) : _key = 'miga.home.v1.$userId';

  // Keep this versioned key and JSON shape stable when reorganizing the code.
  final String _key;

  @override
  Future<HomeDetails> load() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_key);
    return value == null
        ? const HomeDetails()
        : HomeDetails.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  @override
  Future<void> save(HomeDetails details) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(_key, jsonEncode(details.toJson()))) {
      throw StateError('Home details could not be saved');
    }
  }
}
