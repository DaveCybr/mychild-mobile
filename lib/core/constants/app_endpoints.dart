// lib/core/constants/app_endpoints.dart - FIXED VERSION
class ApiEndpoints {
  static const String baseUrl =
      'https://parentalcontrol.satelliteorbit.cloud/api';

  // ============================================
  // DEVICE MANAGEMENT (Child App Uses These)
  // ============================================
  static const String pairDevice = '/devices/pair';
  static const String verifyDevice = '/devices/verify';
  static const String unpairDevice = '/devices/unpair';
  static const String updateFcmToken = '/devices/update-fcm-token'; // ✅ ADDED!

  // ============================================
  // DATA SUBMISSION (Background Service)
  // ============================================
  static const String sendLocation = '/device/locations';
  static const String sendNotification = '/device/notifications';
  static const String sendScreenshot = '/device/screenshots';
  static const String updateDeviceStatus = '/device/{deviceId}/status';

  // ============================================
  // HELPER METHOD
  // ============================================
  static String getUpdateStatusUrl(String deviceId) {
    return updateDeviceStatus.replaceAll('{deviceId}', deviceId);
  }
}
