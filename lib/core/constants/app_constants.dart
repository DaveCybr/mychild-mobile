// core/constants/app_constants.dart
class AppConstants {
  // App Info
  static const String appName = 'Famisafe Child';
  static const String appVersion = '1.0.0';
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double buttonHeight = 56.0;
  
  // Permission Types
  static const String locationPermission = 'location';
  static const String notificationPermission = 'notification';
  static const String batteryPermission = 'battery';
  static const String deviceAdminPermission = 'device_admin';
  static const String cameraPermission = 'camera';
  static const String audioPermission = 'audio';
  static const String storagePermission = 'storage';
  
  // Background Task Names
  static const String locationUpdateTask = 'locationUpdate';
  static const String statusSyncTask = 'statusSync';
  static const String permissionCheckTask = 'permissionCheck';
}
