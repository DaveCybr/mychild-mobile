
// core/storage/secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
      return null;
    }
  }
  
  @override
  Future<void> setString(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      // Log error
    }
  }
  
  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      // Log error
    }
  }
  
  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      // Log error
    }
  }
  
  @override
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      return false;
    }
  }
}
