class ApiEndpoints {
  static const String baseUrl =
      'https://parentalcontrol.satelliteorbit.cloud/api';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';

  // Device
  static const String pairDevice = '/devices/pair';
  static const String verifyDevice = '/devices/verify'; // BARU
  static const String unpairDevice = '/devices/unpair'; // BARU
  static const String updateStatus = '/device/:deviceId/status';

  // Tracking
  static const String sendLocation = '/device/locations';
  static const String sendNotification = '/device/notifications';
  static const String sendScreenshot = '/device/screenshots';

  // Screen Monitoring
  static const String checkActiveSession = '/screen/active-session/:childId';
  static const String sendScreenFrame = '/screen/stream-frame';
  static const String sendScreenshot2 = '/screen/screenshot';

  // Camera
  static const String sendCameraCapture = '/camera/store';
}
