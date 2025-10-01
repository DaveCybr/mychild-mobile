class AppConstants {
  static const String appName = 'Family Safety';
  static const String childAppVersion = '1.0.0';

  // Storage Keys
  static const String keyDeviceId = 'device_id';
  static const String keyChildId = 'child_id';
  static const String keyFamilyCode = 'family_code';
  static const String keyIsPaired = 'is_paired';
  static const String keyParentId = 'parent_id';
  static const String keyAuthToken = 'auth_token';
  static const String keyPermissionCompleted = 'permission_completed'; // BARU

  // Background Service
  static const int locationUpdateInterval = 5; // minutes
  static const int screenCheckInterval = 30; // seconds
  static const int statusUpdateInterval = 1; // minutes

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
