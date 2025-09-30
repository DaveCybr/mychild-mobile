// core/utils/storage_helper.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageHelper {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Generic methods
  static Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  static Future<bool> setInt(String key, int value) {
    return _prefs.setInt(key, value);
  }

  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  static Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  static Future<bool> setJson(String key, Map<String, dynamic> value) {
    return _prefs.setString(key, json.encode(value));
  }

  static Map<String, dynamic>? getJson(String key) {
    final String? jsonString = _prefs.getString(key);
    if (jsonString != null) {
      return json.decode(jsonString);
    }
    return null;
  }

  static Future<bool> remove(String key) {
    return _prefs.remove(key);
  }

  static Future<bool> clear() {
    return _prefs.clear();
  }
}
