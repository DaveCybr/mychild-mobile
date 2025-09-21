class AppConfig {
  // Location tracking settings
  static const int locationUpdateIntervalMinutes = 5;
  static const double minimumDistanceFilter = 10.0; // meters
  static const int lowBatteryThreshold = 20;
  static const int criticalBatteryThreshold = 10;

  // Notification settings
  static const int notificationBatchIntervalSeconds = 30;
  static const int notificationBatchSize = 10;

  // Screen mirroring settings
  static const double maxFpsForStreaming =
      2.0; // 2 FPS for background streaming
  static const Size maxScreenshotSize = Size(720, 1280);

  // API settings
  static const String baseUrl = 'https://your-api-server.com';
  static const int connectionTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 30;

  // Emergency settings
  static const int emergencyLocationTimeoutSeconds = 10;
  static const int emergencyRetryAttempts = 3;

  // Background service settings
  static const String backgroundServiceChannelId = 'parental_control_service';
  static const String backgroundServiceChannelName = 'Safety Monitor Service';
  static const String backgroundServiceChannelDescription =
      'Background service for safety monitoring';
}

class Size {
  final double width;
  final double height;

  const Size(this.width, this.height);
}
