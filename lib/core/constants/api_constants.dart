
// core/constants/api_constants.dart
class ApiConstants {
  // Base URL - sesuai dengan environment
  static const String baseUrl = 'https://parentalcontrol.satelliteorbit.cloud/api';
  
  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';
  static const String user = '/auth/user';
  
  // Family Endpoints
  static const String familyCreate = '/family/create';
  static const String familyJoin = '/family/join';
  static const String familyInfo = '/family/info';
  static const String familyMembers = '/family/members';
  static const String familyLeave = '/family/leave';
  static const String familyUpdate = '/family/update';
  static const String familyRemoveMember = '/family/remove-member';
  
  // Location Endpoints
  static const String locationUpdate = '/location/update';
  static const String locationTrack = '/location/track';
  static const String locationHistory = '/location/history';
  static const String locationTrackAll = '/location/all-children';
  
  // Dashboard Endpoints
  static const String dashboardChild = '/dashboard/child';
  static const String dashboardParent = '/dashboard/parent';
  static const String dashboardAnalytics = '/dashboard/analytics';
  
  // Settings Endpoints
  static const String settings = '/settings';
  static const String settingsUpdate = '/settings';
  static const String settingsBlockedKeywords = '/settings/{childId}/blocked-keywords';
  static const String settingsNotificationFilters = '/settings/{childId}/notification-filters';
  
  // Alert Endpoints
  static const String alertList = '/alert/list';
  static const String alertTrigger = '/alert/trigger';
  static const String alertMarkRead = '/alert/mark-read';
  static const String alertUnreadCount = '/alert/unread-count';
  static const String alertDelete = '/alert';
  
  // Notification Endpoints
  static const String notificationSend = '/notification/send';
  static const String notificationBatchSend = '/notification/batch-send';
  static const String notificationMarkRead = '/notification/mark-read';
  static const String notificationList = '/notification/list';
  static const String notificationUnread = '/notification/unread';
  static const String notificationStatistics = '/notification/statistics';
  
  // Camera Endpoints
  static const String cameraStore = '/camera/store';
  static const String cameraList = '/camera/child';
  static const String cameraShow = '/camera/child/{childId}/{captureId}';
  static const String cameraStream = '/camera/child/{childId}/{captureId}/stream';
  
  // Screen Endpoints
  static const String screenStartSession = '/screen/start-session';
  static const String screenEndSession = '/screen/end-session';
  static const String screenScreenshot = '/screen/screenshot';
  static const String screenStreamFrame = '/screen/stream-frame';
  static const String screenActiveSession = '/screen/active-session';
  static const String screenActiveSessions = '/screen/active-sessions';
  
  // Geofence Endpoints
  static const String geofenceCreate = '/geofence/create';
  static const String geofenceList = '/geofence/list';
  static const String geofenceUpdate = '/geofence';
  static const String geofenceDelete = '/geofence';
  static const String geofenceToggle = '/geofence/{id}/toggle';
  
  // Request Headers
  static const String contentType = 'application/json';
  static const String acceptHeader = 'application/json';
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
}
