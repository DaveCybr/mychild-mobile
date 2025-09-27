
// core/storage/local_storage.dart
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorage {
  String? getString(String key);
  Future<bool> setString(String key, String value);
  bool? getBool(String key);
  Future<bool> setBool(String key, bool value);
  int? getInt(String key);
  Future<bool> setInt(String key, int value);
  double? getDouble(String key);
  Future<bool> setDouble(String key, double value);
  Future<bool> remove(String key);
  Future<bool> clear();
}

class LocalStorageImpl implements LocalStorage {
  final SharedPreferences _prefs;
  
  LocalStorageImpl(this._prefs);
  
  @override
  String? getString(String key) => _prefs.getString(key);
  
  @override
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  
  @override
  bool? getBool(String key) => _prefs.getBool(key);
  
  @override
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  
  @override
  int? getInt(String key) => _prefs.getInt(key);
  
  @override
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  
  @override
  double? getDouble(String key) => _prefs.getDouble(key);
  
  @override
  Future<bool> setDouble(String key, double value) => _prefs.setDouble(key, value);
  
  @override
  Future<bool> remove(String key) => _prefs.remove(key);
  
  @override
  Future<bool> clear() => _prefs.clear();
}