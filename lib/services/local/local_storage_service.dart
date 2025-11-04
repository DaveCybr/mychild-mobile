// lib/services/local/local_storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

class LocalStorageService {
  static late SharedPreferences _prefs;
  static const _secureStorage = FlutterSecureStorage();

  // Public getter for SharedPreferences
  static SharedPreferences get prefs => _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ============================================
  // SAVE METHODS
  // ============================================

  /// Save device info after successful pairing
  static Future<void> saveDeviceInfo({
    required String deviceId,
    required String familyCode,
    required int parentId,
  }) async {
    await _prefs.setString(AppConstants.keyDeviceId, deviceId);
    await _prefs.setString(AppConstants.keyFamilyCode, familyCode);
    await _prefs.setInt(AppConstants.keyParentId, parentId);
    await _prefs.setBool(AppConstants.keyIsPaired, true);
  }

  /// Save FCM token
  static Future<void> saveFcmToken(String token) async {
    await _prefs.setString(AppConstants.keyFcmToken, token);
  }

  /// Save auth token (if needed for future features)
  static Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: AppConstants.keyAuthToken, value: token);
  }

  /// Save permission completion status
  static Future<void> setPermissionCompleted(bool completed) async {
    await _prefs.setBool(AppConstants.keyPermissionCompleted, completed);
  }

  // ✅ ADD: Screen capture permission methods
  /// Save screen capture permission status
  static Future<void> setScreenCapturePermission(bool granted) async {
    await _prefs.setBool('screen_capture_permission_granted', granted);
  }

  /// Get screen capture permission status
  static Future<bool> getScreenCapturePermission() async {
    return _prefs.getBool('screen_capture_permission_granted') ?? false;
  }

  // ============================================
  // GET METHODS
  // ============================================

  /// Get device ID (THIS IS THE CHILD IDENTIFIER!)
  static Future<String?> getDeviceId() async {
    return _prefs.getString(AppConstants.keyDeviceId);
  }

  /// Get family code
  static Future<String?> getFamilyCode() async {
    return _prefs.getString(AppConstants.keyFamilyCode);
  }

  /// Get pairing status
  static Future<bool> getIsPaired() async {
    return _prefs.getBool(AppConstants.keyIsPaired) ?? false;
  }

  /// Get parent ID
  static Future<int?> getParentId() async {
    return _prefs.getInt(AppConstants.keyParentId);
  }

  /// Get FCM token
  static Future<String?> getFcmToken() async {
    return _prefs.getString(AppConstants.keyFcmToken);
  }

  /// Get auth token
  static Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: AppConstants.keyAuthToken);
  }

  /// Get permission completion status
  static Future<bool> isPermissionCompleted() async {
    return _prefs.getBool(AppConstants.keyPermissionCompleted) ?? false;
  }

  // ============================================
  // CLEAR METHODS
  // ============================================

  /// Clear all data
  static Future<void> clearAll() async {
    await _prefs.clear();
    await _secureStorage.deleteAll();
  }

  /// Clear pairing data only
  static Future<void> clearPairing() async {
    await _prefs.remove(AppConstants.keyDeviceId);
    await _prefs.remove(AppConstants.keyFamilyCode);
    await _prefs.remove(AppConstants.keyParentId);
    await _prefs.setBool(AppConstants.keyIsPaired, false);
    await _prefs.remove(AppConstants.keyPermissionCompleted);
    await _prefs.remove(AppConstants.keyFcmToken);
    await _prefs.remove(
      'screen_capture_permission_granted',
    ); // ✅ ADD: Clear screen capture permission
    await _secureStorage.delete(key: AppConstants.keyAuthToken);
  }
}
