import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

class LocalStorageService {
  static late SharedPreferences _prefs;
  static const _secureStorage = FlutterSecureStorage();

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Save methods
  static Future<void> saveDeviceInfo({
    required String deviceId,
    required String familyCode,
    required int parentId,
  }) async {
    await _prefs.setString(AppConstants.keyDeviceId, deviceId);
    await _prefs.setString(AppConstants.keyFamilyCode, familyCode);
    await _prefs.setInt(AppConstants.keyParentId, parentId);
    await _prefs.setBool(AppConstants.keyIsPaired, true);

    // Generate child ID (can be UUID or device-specific)
    final childId = '${deviceId}_${DateTime.now().millisecondsSinceEpoch}';
    await _prefs.setString(AppConstants.keyChildId, childId);
  }

  static Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: AppConstants.keyAuthToken, value: token);
  }

  // BARU: Save permission completion status
  static Future<void> setPermissionCompleted(bool completed) async {
    await _prefs.setBool(AppConstants.keyPermissionCompleted, completed);
  }

  // Get methods
  static Future<String?> getDeviceId() async {
    return _prefs.getString(AppConstants.keyDeviceId);
  }

  static Future<String?> getChildId() async {
    return _prefs.getString(AppConstants.keyChildId);
  }

  static Future<String?> getFamilyCode() async {
    return _prefs.getString(AppConstants.keyFamilyCode);
  }

  static Future<bool> getIsPaired() async {
    return _prefs.getBool(AppConstants.keyIsPaired) ?? false;
  }

  static Future<int?> getParentId() async {
    return _prefs.getInt(AppConstants.keyParentId);
  }

  static Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: AppConstants.keyAuthToken);
  }

  // BARU: Get permission completion status
  static Future<bool> isPermissionCompleted() async {
    return _prefs.getBool(AppConstants.keyPermissionCompleted) ?? false;
  }

  // Clear methods
  static Future<void> clearAll() async {
    await _prefs.clear();
    await _secureStorage.deleteAll();
  }

  static Future<void> clearPairing() async {
    await _prefs.remove(AppConstants.keyDeviceId);
    await _prefs.remove(AppConstants.keyChildId);
    await _prefs.remove(AppConstants.keyFamilyCode);
    await _prefs.remove(AppConstants.keyParentId);
    await _prefs.setBool(AppConstants.keyIsPaired, false);
    await _prefs.remove(AppConstants.keyPermissionCompleted);
    await _secureStorage.delete(key: AppConstants.keyAuthToken);
  }
}
