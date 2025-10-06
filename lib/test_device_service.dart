import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  // PENTING: Key harus sama dengan yang di native Android
  static const String _keyDeviceId =
      'flutter.device_id'; // Tambahkan prefix "flutter."
  static const String _keyIsPaired = 'flutter.is_paired'; // Untuk BootReceiver

  /// Get or generate device ID
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_keyDeviceId);

    if (deviceId == null || deviceId.isEmpty) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id; // Android ID

      await prefs.setString(_keyDeviceId, deviceId);
      // Set is_paired juga agar BootReceiver bisa restart service
      await prefs.setBool(_keyIsPaired, true);

      print('Device ID generated and saved: $deviceId');
    } else {
      print('Device ID loaded from storage: $deviceId');
    }

    return deviceId;
  }

  /// Set device ID manually
  static Future<void> setDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeviceId, deviceId);
    await prefs.setBool(_keyIsPaired, true);
    print('Device ID manually set: $deviceId');
  }

  /// Check if device is paired
  static Future<bool> isPaired() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsPaired) ?? false;
  }

  /// Clear device data (for unpair)
  static Future<void> clearDeviceData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDeviceId);
    await prefs.setBool(_keyIsPaired, false);
    print('Device data cleared');
  }
}
