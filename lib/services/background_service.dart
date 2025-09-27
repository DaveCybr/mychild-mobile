// lib/services/background_service.dart
import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'api_service.dart';
import 'location_service.dart';
import 'notification_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  late ApiService _apiService;
  late LocationService _locationService;
  late NotificationService _notificationService;

  Timer? _healthCheckTimer;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _apiService = ApiService();
    await _apiService.loadSavedToken();

    _locationService = LocationService(_apiService);
    _notificationService = NotificationService(_apiService);

    _isInitialized = true;

    // Start health check timer
    _startHealthCheck();
  }

  Future<void> startLocationTracking() async {
    try {
      await _locationService.startTracking();
      print('Background location tracking started');
    } catch (e) {
      print('Failed to start location tracking: $e');
    }
  }

  Future<void> startNotificationMonitoring() async {
    try {
      await _notificationService.startListening();
      print('Background notification monitoring started');
    } catch (e) {
      print('Failed to start notification monitoring: $e');
    }
  }

  void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 5), (
      timer,
    ) async {
      await _performHealthCheck();
    });
  }

  Future<void> _performHealthCheck() async {
    try {
      // Check if services are still running
      final isLocationActive =
          _locationService.isTracking; // Fixed: use public getter
      final isNotificationActive =
          _notificationService
              .isListening; // You'll need to add this getter too

      // Try to process offline queue
      await _apiService.processOfflineQueue();

      // Update service notification
      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        service.invoke('update_notification', {
          'title': 'Safety Monitor Active',
          'content':
              'Location: ${isLocationActive ? '✓' : '✗'} | Notifications: ${isNotificationActive ? '✓' : '✗'}',
        });
      }

      print(
        'Health check completed - Location: $isLocationActive, Notifications: $isNotificationActive',
      );
    } catch (e) {
      print('Health check failed: $e');
    }
  }

  // Emergency location ping
  Future<void> sendEmergencyLocation(
    String emergencyType, {
    String? message,
  }) async {
    try {
      final position = await _locationService.getEmergencyLocation();

      if (position != null) {
        await _apiService.triggerEmergency(
          latitude: position.latitude,
          longitude: position.longitude,
          emergencyType: emergencyType,
          message: message,
        );
      }
    } catch (e) {
      print('Failed to send emergency location: $e');
    }
  }

  void dispose() {
    _healthCheckTimer?.cancel();
    _locationService.dispose();
    _notificationService.dispose();
  }
}
