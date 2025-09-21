// lib/services/api_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_config.dart';

class ApiService {
  late Dio _dio;
  String? _authToken;

  ApiService() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Request interceptor for auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }

          // Add device headers
          options.headers['X-Device-ID'] = await _getDeviceId();
          options.headers['X-Device-Type'] = 'android_child';
          options.headers['X-App-Version'] = '1.0.0';

          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired, try refresh or logout
            await _handleAuthError();
          }
          handler.next(error);
        },
      ),
    );

    // Logging interceptor for development
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print(obj),
      ),
    );
  }

  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');

    if (deviceId == null) {
      // Generate unique device ID
      deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('device_id', deviceId);
    }

    return deviceId;
  }

  Future<void> _handleAuthError() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    // Navigate to login screen
  }

  // Authentication Methods
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final authResponse = AuthResponse.fromJson(response.data);
      _authToken = authResponse.token;

      // Save token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _authToken!);

      return authResponse;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Continue with local logout even if server request fails
    } finally {
      _authToken = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    }
  }

  Future<void> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  // Location Methods
  Future<ApiResponse> updateLocation({
    required double latitude,
    required double longitude,
    required double accuracy,
    required int batteryLevel,
  }) async {
    try {
      final response = await _dio.post(
        '/location/update',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
          'battery_level': batteryLevel,
        },
      );

      return ApiResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Notification Methods
  Future<ApiResponse> sendNotification({
    required String appPackage,
    required String title,
    required String content,
    required int priority,
    String? category,
  }) async {
    try {
      final response = await _dio.post(
        '/notification/send',
        data: {
          'app_package': appPackage,
          'title': title,
          'content': content,
          'priority': priority,
          'category': category,
        },
      );

      return ApiResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse> batchSendNotifications(
    List<NotificationData> notifications,
  ) async {
    try {
      final response = await _dio.post(
        '/notification/batch-send',
        data: {'notifications': notifications.map((n) => n.toJson()).toList()},
      );

      return ApiResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Alert Methods
  Future<ApiResponse> triggerAlert({
    required String type,
    required String priority,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post(
        '/alert/trigger',
        data: {
          'type': type,
          'priority': priority,
          'title': title,
          'message': message,
          'data': data,
        },
      );

      return ApiResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse> triggerEmergency({
    required double latitude,
    required double longitude,
    required String emergencyType,
    String? message,
  }) async {
    try {
      final response = await _dio.post(
        '/alert/emergency',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'emergency_type': emergencyType,
          'message': message,
        },
      );

      return ApiResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Screen Mirroring Methods
  Future<ScreenSessionResponse> getActiveScreenSession() async {
    try {
      final user = await getCurrentUser();
      final response = await _dio.get('/screen/active-session/${user.id}');

      return ScreenSessionResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse> sendScreenshot({
    required String sessionToken,
    required String screenshotBase64,
  }) async {
    try {
      final response = await _dio.post(
        '/screen/screenshot',
        data: {
          'session_token': sessionToken,
          'screenshot': screenshotBase64,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return ApiResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse> sendStreamFrame({
    required String sessionToken,
    required String frameData,
    required int frameNumber,
  }) async {
    try {
      final response = await _dio.post(
        '/screen/stream-frame',
        data: {
          'session_token': sessionToken,
          'frame_data': frameData,
          'frame_number': frameNumber,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return ApiResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Dashboard Methods
  Future<ChildDashboardResponse> getChildDashboard() async {
    try {
      final response = await _dio.get('/dashboard/child');
      return ChildDashboardResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Settings Methods
  Future<AppSettingsResponse> getSettings() async {
    try {
      final user = await getCurrentUser();
      final response = await _dio.get('/settings/${user.id}');
      return AppSettingsResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Family Methods
  Future<ApiResponse> joinFamily(String familyCode) async {
    try {
      final response = await _dio.post(
        '/family/join',
        data: {'family_code': familyCode},
      );

      return ApiResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<FamilyMembersResponse> getFamilyMembers() async {
    try {
      final response = await _dio.get('/family/members');
      return FamilyMembersResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // User Methods
  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/user');
      return User.fromJson(response.data['user']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Offline Queue Management
  final List<Map<String, dynamic>> _offlineQueue = [];

  Future<void> addToOfflineQueue(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    _offlineQueue.add({
      'endpoint': endpoint,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'method': 'POST',
    });

    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_queue', jsonEncode(_offlineQueue));
  }

  Future<void> processOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;

    for (int i = _offlineQueue.length - 1; i >= 0; i--) {
      try {
        final item = _offlineQueue[i];
        await _dio.post(item['endpoint'], data: item['data']);
        _offlineQueue.removeAt(i);
      } catch (e) {
        // Keep failed items in queue
        print('Failed to process offline item: $e');
      }
    }

    // Update local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_queue', jsonEncode(_offlineQueue));
  }

  Future<void> loadOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString('offline_queue');

    if (queueJson != null) {
      final List<dynamic> queue = jsonDecode(queueJson);
      _offlineQueue.clear();
      _offlineQueue.addAll(queue.cast<Map<String, dynamic>>());
    }
  }

  // Error Handling
  String _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['message'] ?? 'Server error';
          return 'Error $statusCode: $message';
        case DioExceptionType.cancel:
          return 'Request cancelled';
        default:
          return 'Network error. Please try again.';
      }
    }
    return error.toString();
  }

  // Connection Status
  bool get isConnected => _authToken != null;

  // Cleanup
  void dispose() {
    _dio.close();
  }
}

// lib/models/api_models.dart
class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;

  ApiResponse({required this.success, required this.message, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

class AuthResponse extends ApiResponse {
  final String token;
  final User user;

  AuthResponse({
    required bool success,
    required String message,
    required this.token,
    required this.user,
  }) : super(success: success, message: message);

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'],
      message: json['message'] ?? '',
      token: json['token'],
      user: User.fromJson(json['user']),
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      phone: json['phone'],
    );
  }
}

class NotificationData {
  final String appPackage;
  final String title;
  final String content;
  final int priority;
  final String? category;
  final DateTime timestamp;

  NotificationData({
    required this.appPackage,
    required this.title,
    required this.content,
    required this.priority,
    this.category,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'app_package': appPackage,
      'title': title,
      'content': content,
      'priority': priority,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ScreenSessionResponse extends ApiResponse {
  final ScreenSession? activeSession;
  final bool isBeingMonitored;

  ScreenSessionResponse({
    required bool success,
    required String message,
    this.activeSession,
    required this.isBeingMonitored,
  }) : super(success: success, message: message);

  factory ScreenSessionResponse.fromJson(Map<String, dynamic> json) {
    return ScreenSessionResponse(
      success: json['success'],
      message: json['message'] ?? '',
      activeSession:
          json['active_session'] != null
              ? ScreenSession.fromJson(json['active_session'])
              : null,
      isBeingMonitored: json['is_being_monitored'],
    );
  }
}

class ScreenSession {
  final int id;
  final String sessionToken;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool isActive;

  ScreenSession({
    required this.id,
    required this.sessionToken,
    required this.startedAt,
    this.endedAt,
    required this.isActive,
  });

  factory ScreenSession.fromJson(Map<String, dynamic> json) {
    return ScreenSession(
      id: json['id'],
      sessionToken: json['session_token'],
      startedAt: DateTime.parse(json['started_at']),
      endedAt:
          json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      isActive: json['is_active'],
    );
  }
}

class ChildDashboardResponse extends ApiResponse {
  final ChildDashboard dashboard;

  ChildDashboardResponse({
    required bool success,
    required String message,
    required this.dashboard,
  }) : super(success: success, message: message);

  factory ChildDashboardResponse.fromJson(Map<String, dynamic> json) {
    return ChildDashboardResponse(
      success: json['success'],
      message: json['message'] ?? '',
      dashboard: ChildDashboard.fromJson(json['dashboard']),
    );
  }
}

class ChildDashboard {
  final User user;
  final Family? family;
  final DashboardStats stats;
  final List<Alert> recentAlerts;

  ChildDashboard({
    required this.user,
    this.family,
    required this.stats,
    required this.recentAlerts,
  });

  factory ChildDashboard.fromJson(Map<String, dynamic> json) {
    return ChildDashboard(
      user: User.fromJson(json['user']),
      family: json['family'] != null ? Family.fromJson(json['family']) : null,
      stats: DashboardStats.fromJson(json['stats']),
      recentAlerts:
          (json['recent_alerts'] as List)
              .map((alert) => Alert.fromJson(alert))
              .toList(),
    );
  }
}

class Family {
  final int id;
  final String name;
  final String familyCode;

  Family({required this.id, required this.name, required this.familyCode});

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'],
      name: json['name'],
      familyCode: json['family_code'],
    );
  }
}

class DashboardStats {
  final int notificationsToday;
  final int notificationsWeek;
  final int locationUpdatesToday;
  final int activeAlerts;

  DashboardStats({
    required this.notificationsToday,
    required this.notificationsWeek,
    required this.locationUpdatesToday,
    required this.activeAlerts,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      notificationsToday: json['notifications_today'],
      notificationsWeek: json['notifications_week'],
      locationUpdatesToday: json['location_updates_today'],
      activeAlerts: json['active_alerts'],
    );
  }
}

class Alert {
  final int id;
  final String type;
  final String priority;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final DateTime triggeredAt;
  final bool isRead;

  Alert({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.data,
    required this.triggeredAt,
    required this.isRead,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      type: json['type'],
      priority: json['priority'],
      title: json['title'],
      message: json['message'],
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      triggeredAt: DateTime.parse(json['triggered_at']),
      isRead: json['is_read'],
    );
  }
}

class FamilyMembersResponse extends ApiResponse {
  final List<FamilyMember> members;

  FamilyMembersResponse({
    required bool success,
    required String message,
    required this.members,
  }) : super(success: success, message: message);

  factory FamilyMembersResponse.fromJson(Map<String, dynamic> json) {
    return FamilyMembersResponse(
      success: json['success'],
      message: json['message'] ?? '',
      members:
          (json['members'] as List)
              .map((member) => FamilyMember.fromJson(member))
              .toList(),
    );
  }
}

class FamilyMember {
  final int id;
  final User user;
  final String role;
  final bool isPrimary;

  FamilyMember({
    required this.id,
    required this.user,
    required this.role,
    required this.isPrimary,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'],
      user: User.fromJson(json['user']),
      role: json['role'],
      isPrimary: json['is_primary'],
    );
  }
}

class AppSettingsResponse extends ApiResponse {
  final AppSettings settings;

  AppSettingsResponse({
    required bool success,
    required String message,
    required this.settings,
  }) : super(success: success, message: message);

  factory AppSettingsResponse.fromJson(Map<String, dynamic> json) {
    return AppSettingsResponse(
      success: json['success'],
      message: json['message'] ?? '',
      settings: AppSettings.fromJson(json['settings']),
    );
  }
}

class AppSettings {
  final Map<String, bool> notificationFilters;
  final List<String> blockedKeywords;
  final int locationUpdateInterval;
  final bool screenMirroringEnabled;
  final Map<String, dynamic> geofenceSettings;

  AppSettings({
    required this.notificationFilters,
    required this.blockedKeywords,
    required this.locationUpdateInterval,
    required this.screenMirroringEnabled,
    required this.geofenceSettings,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationFilters: Map<String, bool>.from(
        json['notification_filters'] ?? {},
      ),
      blockedKeywords: List<String>.from(json['blocked_keywords'] ?? []),
      locationUpdateInterval: json['location_update_interval'] ?? 60,
      screenMirroringEnabled: json['screen_mirroring_enabled'] ?? false,
      geofenceSettings: Map<String, dynamic>.from(
        json['geofence_settings'] ?? {},
      ),
    );
  }
}
