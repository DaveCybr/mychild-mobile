
// core/storage/hive_boxes.dart
import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  static const String userBox = 'user_box';
  static const String settingsBox = 'settings_box';
  static const String cacheBox = 'cache_box';
  
  static Box? _userBox;
  static Box? _settingsBox;
  static Box? _cacheBox;
  
  static Future<void> init() async {
    _userBox = await Hive.openBox(userBox);
    _settingsBox = await Hive.openBox(settingsBox);
    _cacheBox = await Hive.openBox(cacheBox);
  }
  
  static Box get user {
    if (_userBox == null || !_userBox!.isOpen) {
      throw Exception('User box is not initialized');
    }
    return _userBox!;
  }
  
  static Box get settings {
    if (_settingsBox == null || !_settingsBox!.isOpen) {
      throw Exception('Settings box is not initialized');
    }
    return _settingsBox!;
  }
  
  static Box get cache {
    if (_cacheBox == null || !_cacheBox!.isOpen) {
      throw Exception('Cache box is not initialized');
    }
    return _cacheBox!;
  }
  
  static Future<void> clearAll() async {
    await _userBox?.clear();
    await _settingsBox?.clear();
    await _cacheBox?.clear();
  }
}
