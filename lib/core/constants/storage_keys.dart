
// core/constants/storage_keys.dart
class StorageKeys {
  // User Data
  static const String userToken = 'user_token';
  static const String refreshToken = 'refresh_token';
  static const String userData = 'user_data';
  static const String userId = 'user_id';
  
  // App State
  static const String isFirstLaunch = 'is_first_launch';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String permissionSetupCompleted = 'permission_setup_completed';
  
  // Family Data
  static const String familyId = 'family_id';
  static const String familyData = 'family_data';
  static const String familyCode = 'family_code';
  
  // Settings
  static const String locationTrackingEnabled = 'location_tracking_enabled';
  static const String backgroundServiceEnabled = 'background_service_enabled';
  static const String notificationsEnabled = 'notifications_enabled';
  
  // Permission Status
  static const String locationPermissionStatus = 'location_permission_status';
  static const String notificationPermissionStatus = 'notification_permission_status';
  static const String batteryPermissionStatus = 'battery_permission_status';
  static const String deviceAdminPermissionStatus = 'device_admin_permission_status';
  static const String cameraPermissionStatus = 'camera_permission_status';
  static const String audioPermissionStatus = 'audio_permission_status';
  static const String storagePermissionStatus = 'storage_permission_status';
  
  // Device Info
  static const String deviceId = 'device_id';
  static const String deviceInfo = 'device_info';
  static const String lastLocationUpdate = 'last_location_update';
  
  // Cache
  static const String cacheExpiry = 'cache_expiry';
  static const String cachedDashboardData = 'cached_dashboard_data';
}
