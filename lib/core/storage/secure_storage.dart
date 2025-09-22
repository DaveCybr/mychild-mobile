// core/storage/secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SecureStorage {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<bool> containsKey(String key);
}

class SecureStorageImpl implements SecureStorage {
  final FlutterSecureStorage _storage;
  
  SecureStorageImpl(this._storage);
  
  @override
  Future<String?> getString(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      print('SecureStorage getString error for key $key: $e');
      return null;
    }
  }
  
  @override
  Future<void> setString(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      print('SecureStorage setString error for key $key: $e');
    }
  }
  
  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      print('SecureStorage delete error for key $key: $e');
    }
  }
  
  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      print('SecureStorage deleteAll error: $e');
    }
  }
  
  @override
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      print('SecureStorage containsKey error for key $key: $e');
      return false;
    }
  }
}

// Fallback implementation using SharedPreferences jika SecureStorage gagal
class SecureStorageFallback implements SecureStorage {
  final SharedPreferences _prefs;
  
  SecureStorageFallback(this._prefs);
  
  @override
  Future<String?> getString(String key) async {
    try {
      return _prefs.getString('secure_$key');
    } catch (e) {
      print('SecureStorageFallback getString error for key $key: $e');
      return null;
    }
  }
  
  @override
  Future<void> setString(String key, String value) async {
    try {
      await _prefs.setString('secure_$key', value);
    } catch (e) {
      print('SecureStorageFallback setString error for key $key: $e');
    }
  }
  
  @override
  Future<void> delete(String key) async {
    try {
      await _prefs.remove('secure_$key');
    } catch (e) {
      print('SecureStorageFallback delete error for key $key: $e');
    }
  }
  
  @override
  Future<void> deleteAll() async {
    try {
      final keys = _prefs.getKeys().where((key) => key.startsWith('secure_'));
      for (final key in keys) {
        await _prefs.remove(key);
      }
    } catch (e) {
      print('SecureStorageFallback deleteAll error: $e');
    }
  }
  
  @override
  Future<bool> containsKey(String key) async {
    try {
      return _prefs.containsKey('secure_$key');
    } catch (e) {
      print('SecureStorageFallback containsKey error for key $key: $e');
      return false;
    }
  }
}