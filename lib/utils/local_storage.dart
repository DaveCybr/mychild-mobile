import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class LocalStorageService {
  static const String _tag = 'LocalStorageService';

  // Keys
  static const String _keyDeviceId = 'device_id';
  static const String _keyFamilyCode = 'family_code';
  static const String _keyParentId = 'parent_id';
  static const String _keyIsPaired = 'is_paired';
  static const String _keyDeviceName = 'device_name';
  static const String _keyFcmToken = 'fcm_token';
  static const String _keyLastSync = 'last_sync';
  static const String _keyPermissionCompleted = 'permission_completed';

  static Future<void> saveDeviceId(String deviceId) async {
    try {
      developer.log('💾 Saving device ID', name: _tag);
      final prefs = await SharedPreferences.getInstance();

      // Save for Flutter
      await prefs.setString(_keyDeviceId, deviceId);

      // Save for Android Native (with prefix)
      await prefs.setString('flutter.$_keyDeviceId', deviceId);

      developer.log(
        '✅ Device ID saved: ${deviceId.substring(0, 8)}...',
        name: _tag,
      );
    } catch (e) {
      developer.log('❌ Failed to save device ID', name: _tag, error: e);
      rethrow;
    }
  }

  // Save device info after pairing
  static Future<void> saveDeviceInfo({
    required String deviceId,
    required String familyCode,
    required int parentId,
    String? deviceName,
  }) async {
    try {
      developer.log('Saving device info to SharedPreferences', name: _tag);
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_keyDeviceId, deviceId);
      await prefs.setString(_keyFamilyCode, familyCode);
      await prefs.setInt(_keyParentId, parentId);
      await prefs.setBool(_keyIsPaired, true);

      if (deviceName != null) {
        await prefs.setString(_keyDeviceName, deviceName);
      }

      // Save timestamp
      await prefs.setString(_keyLastSync, DateTime.now().toIso8601String());

      developer.log('✅ Device info saved successfully', name: _tag);
      developer.log('  DeviceId: $deviceId', name: _tag);
      developer.log('  FamilyCode: $familyCode', name: _tag);
      developer.log('  ParentId: $parentId', name: _tag);
      developer.log('  IsPaired: true', name: _tag);
    } catch (e) {
      developer.log('❌ Failed to save device info', name: _tag, error: e);
      rethrow;
    }
  }

  // Get device ID
  static Future<String?> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyDeviceId);
    } catch (e) {
      developer.log('Error getting device ID', name: _tag, error: e);
      return null;
    }
  }

  // Get family code
  static Future<String?> getFamilyCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyFamilyCode);
    } catch (e) {
      developer.log('Error getting family code', name: _tag, error: e);
      return null;
    }
  }

  // Get parent ID
  static Future<int?> getParentId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyParentId);
    } catch (e) {
      developer.log('Error getting parent ID', name: _tag, error: e);
      return null;
    }
  }

  // Check if device is paired
  static Future<bool> getIsPaired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPaired = prefs.getBool(_keyIsPaired) ?? false;
      developer.log('IsPaired: $isPaired', name: _tag);
      return isPaired;
    } catch (e) {
      developer.log('Error checking paired status', name: _tag, error: e);
      return false;
    }
  }

  // Save FCM token
  static Future<void> saveFcmToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFcmToken, token);
      developer.log('✅ FCM token saved', name: _tag);
    } catch (e) {
      developer.log('❌ Failed to save FCM token', name: _tag, error: e);
    }
  }

  // Get FCM token
  static Future<String?> getFcmToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyFcmToken);
    } catch (e) {
      developer.log('Error getting FCM token', name: _tag, error: e);
      return null;
    }
  }

  // Save device name
  static Future<void> saveDeviceName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDeviceName, name);
      developer.log('Device name saved: $name', name: _tag);
    } catch (e) {
      developer.log('Error saving device name', name: _tag, error: e);
    }
  }

  // Get device name
  static Future<String?> getDeviceName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyDeviceName);
    } catch (e) {
      developer.log('Error getting device name', name: _tag, error: e);
      return null;
    }
  }

  // Update last sync timestamp
  static Future<void> updateLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastSync, DateTime.now().toIso8601String());
    } catch (e) {
      developer.log('Error updating last sync', name: _tag, error: e);
    }
  }

  // Get last sync timestamp
  static Future<DateTime?> getLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_keyLastSync);
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
      return null;
    } catch (e) {
      developer.log('Error getting last sync', name: _tag, error: e);
      return null;
    }
  }

  // ============ PERMISSION STATUS ============

  // Set permission completed
  static Future<void> setPermissionCompleted(bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPermissionCompleted, completed);
      developer.log('✅ Permission completed: $completed', name: _tag);
    } catch (e) {
      developer.log('❌ Failed to save permission status', name: _tag, error: e);
    }
  }

  // Check if permission is completed
  static Future<bool> isPermissionCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyPermissionCompleted) ?? false;
    } catch (e) {
      developer.log('Error checking permission status', name: _tag, error: e);
      return false;
    }
  }

  // ============ CLEAR DATA ============

  // Clear all data (unpair device)
  static Future<void> clearAll() async {
    try {
      developer.log('🗑️ Clearing all device data', name: _tag);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyDeviceId);
      await prefs.remove(_keyFamilyCode);
      await prefs.remove(_keyParentId);
      await prefs.remove(_keyIsPaired);
      await prefs.remove(_keyDeviceName);
      await prefs.remove(_keyFcmToken);
      await prefs.remove(_keyLastSync);
      await prefs.remove(_keyPermissionCompleted);
      developer.log('✅ All data cleared', name: _tag);
    } catch (e) {
      developer.log('❌ Failed to clear data', name: _tag, error: e);
      rethrow;
    }
  }

  // Get all device info as Map
  static Future<Map<String, dynamic>> getAllDeviceInfo() async {
    return {
      'device_id': await getDeviceId(),
      'family_code': await getFamilyCode(),
      'parent_id': await getParentId(),
      'is_paired': await getIsPaired(),
      'device_name': await getDeviceName(),
      'fcm_token': await getFcmToken(),
      'last_sync': await getLastSync(),
      'permission_completed': await isPermissionCompleted(),
    };
  }
}
