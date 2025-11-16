import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

/// Helper class untuk sync data antara Flutter dan Android Native
/// Android Native membaca SharedPreferences dengan prefix "flutter."
class NativeBridgeHelper {
  static const String _tag = 'NativeBridgeHelper';
  static const _locationChannel = MethodChannel('location_worker_channel');
  static const _serviceChannel = MethodChannel(
    'com.example.couple_guard_child/service',
  );

  /// Sync device data ke Android Native
  /// Android Native hanya bisa baca key dengan prefix "flutter."
  static Future<void> syncDeviceDataToNative({
    required String deviceId,
    required bool isPaired,
    String? familyCode,
    int? parentId,
  }) async {
    try {
      developer.log('========================================', name: _tag);
      developer.log('🔄 Syncing device data to Android Native', name: _tag);

      final prefs = await SharedPreferences.getInstance();

      // Set untuk Flutter (tanpa prefix)
      await prefs.setString('device_id', deviceId);
      await prefs.setBool('is_paired', isPaired);

      if (familyCode != null) {
        await prefs.setString('family_code', familyCode);
      }

      if (parentId != null) {
        await prefs.setInt('parent_id', parentId);
      }

      // Set untuk Android Native (dengan prefix "flutter.")
      await prefs.setString('flutter.device_id', deviceId);
      await prefs.setBool('flutter.is_paired', isPaired);

      if (familyCode != null) {
        await prefs.setString('flutter.family_code', familyCode);
      }

      if (parentId != null) {
        await prefs.setInt('flutter.parent_id', parentId);
      }

      developer.log('✅ Data synced successfully', name: _tag);
      developer.log('  device_id: ${deviceId.substring(0, 8)}...', name: _tag);
      developer.log('  is_paired: $isPaired', name: _tag);
      if (familyCode != null) {
        developer.log('  family_code: $familyCode', name: _tag);
      }
      if (parentId != null) {
        developer.log('  parent_id: $parentId', name: _tag);
      }
      developer.log('========================================', name: _tag);
    } catch (e) {
      developer.log('❌ Failed to sync data to native', name: _tag, error: e);
      rethrow;
    }
  }

  /// Clear device data dari Flutter dan Native
  static Future<void> clearDeviceDataFromNative() async {
    try {
      developer.log('🗑️ Clearing device data from Native', name: _tag);

      final prefs = await SharedPreferences.getInstance();

      // Remove Flutter keys
      await prefs.remove('device_id');
      await prefs.remove('is_paired');
      await prefs.remove('family_code');
      await prefs.remove('parent_id');

      // Remove Native keys
      await prefs.remove('flutter.device_id');
      await prefs.remove('flutter.is_paired');
      await prefs.remove('flutter.family_code');
      await prefs.remove('flutter.parent_id');

      developer.log('✅ Device data cleared', name: _tag);
    } catch (e) {
      developer.log('❌ Failed to clear data', name: _tag, error: e);
    }
  }

  /// Start PersistentService dan WorkManager
  static Future<bool> startTrackingServices() async {
    try {
      developer.log('🚀 Starting tracking services', name: _tag);

      // Start WorkManager via location channel
      await _locationChannel.invokeMethod('startPeriodicLocation');
      developer.log('✅ Location worker started', name: _tag);

      // Start PersistentService via service channel (optional, sudah dihandle di startPeriodicLocation)
      try {
        await _serviceChannel.invokeMethod('startService');
        developer.log('✅ Persistent service started', name: _tag);
      } catch (e) {
        developer.log(
          '⚠️ Service channel not available (OK jika sudah start)',
          name: _tag,
        );
      }

      return true;
    } catch (e) {
      developer.log(
        '❌ Failed to start tracking services',
        name: _tag,
        error: e,
      );
      return false;
    }
  }

  /// Stop tracking services
  static Future<bool> stopTrackingServices() async {
    try {
      developer.log('🛑 Stopping tracking services', name: _tag);

      await _serviceChannel.invokeMethod('stopService');
      developer.log('✅ Services stopped', name: _tag);

      return true;
    } catch (e) {
      developer.log('❌ Failed to stop services', name: _tag, error: e);
      return false;
    }
  }

  /// Check if tracking services are running
  static Future<bool> isTrackingServicesRunning() async {
    try {
      final isRunning = await _serviceChannel.invokeMethod<bool>(
        'isServiceRunning',
      );
      developer.log('Service running: ${isRunning ?? false}', name: _tag);
      return isRunning ?? false;
    } catch (e) {
      developer.log('❌ Failed to check service status', name: _tag, error: e);
      return false;
    }
  }

  /// Get device ID from SharedPreferences (reads both Flutter and Native keys)
  static Future<String?> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try Flutter key first
      String? deviceId = prefs.getString('device_id');

      // Fallback to Native key
      deviceId ??= prefs.getString('flutter.device_id');

      return deviceId;
    } catch (e) {
      developer.log('Error getting device ID', name: _tag, error: e);
      return null;
    }
  }

  /// Check if device is paired (reads both Flutter and Native keys)
  static Future<bool> isPaired() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try Flutter key first
      bool? isPaired = prefs.getBool('is_paired');

      // Fallback to Native key
      isPaired ??= prefs.getBool('flutter.is_paired');

      return isPaired ?? false;
    } catch (e) {
      developer.log('Error checking paired status', name: _tag, error: e);
      return false;
    }
  }

  /// Test send location via Native (for debugging)
  static Future<bool> testSendLocation() async {
    try {
      developer.log('🧪 Testing send location via Native', name: _tag);
      final result = await _serviceChannel.invokeMethod<bool>(
        'testSendLocation',
      );
      developer.log('Test result: $result', name: _tag);
      return result ?? false;
    } catch (e) {
      developer.log('❌ Test failed', name: _tag, error: e);
      return false;
    }
  }

  /// Test send notification via Native (for debugging)
  static Future<bool> testSendNotification() async {
    try {
      developer.log('🧪 Testing send notification via Native', name: _tag);
      final result = await _serviceChannel.invokeMethod<bool>(
        'testSendNotification',
      );
      developer.log('Test result: $result', name: _tag);
      return result ?? false;
    } catch (e) {
      developer.log('❌ Test failed', name: _tag, error: e);
      return false;
    }
  }

  /// Verify sync status (debugging helper)
  static Future<Map<String, dynamic>> verifySyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final flutterDeviceId = prefs.getString('device_id');
      final nativeDeviceId = prefs.getString('flutter.device_id');
      final flutterIsPaired = prefs.getBool('is_paired');
      final nativeIsPaired = prefs.getBool('flutter.is_paired');

      final status = {
        'flutter': {'device_id': flutterDeviceId, 'is_paired': flutterIsPaired},
        'native': {'device_id': nativeDeviceId, 'is_paired': nativeIsPaired},
        'synced':
            flutterDeviceId == nativeDeviceId &&
            flutterIsPaired == nativeIsPaired,
      };

      developer.log('Sync Status:', name: _tag);
      developer.log('  Flutter device_id: $flutterDeviceId', name: _tag);
      developer.log('  Native device_id: $nativeDeviceId', name: _tag);
      developer.log('  Flutter is_paired: $flutterIsPaired', name: _tag);
      developer.log('  Native is_paired: $nativeIsPaired', name: _tag);
      developer.log('  Synced: ${status['synced']}', name: _tag);

      return status;
    } catch (e) {
      developer.log('Error verifying sync status', name: _tag, error: e);
      return {'error': e.toString()};
    }
  }
}
