import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/home_details.dart';

class HomeDetailsStore {
  HomeDetailsStore(String userId) : _key = 'miga.home.v1.$userId';

  final String _key;

  Future<HomeDetails> load() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_key);
    return value == null
        ? const HomeDetails()
        : HomeDetails.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  Future<void> save(HomeDetails details) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(_key, jsonEncode(details.toJson()))) {
      throw StateError('Home details could not be saved');
    }
  }
}
