import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_config.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService;
  static const MethodChannel _channel = MethodChannel('notification_listener');

  bool _isListening = false;
  Timer? _batchTimer;
  final List<NotificationData> _pendingNotifications = [];

  bool get isListening => _isListening;

  NotificationService(this._apiService) {
    _setupMethodChannel();
  }

  void _setupMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onNotificationReceived':
          await _handleNotificationReceived(call.arguments);
          break;
        case 'onNotificationRemoved':
          await _handleNotificationRemoved(call.arguments);
          break;
      }
    });
  }

  // Request notification access permission
  Future<bool> requestNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod('requestNotificationAccess');
      return result == true;
    } catch (e) {
      print('Failed to request notification permission: $e');
      return false;
    }
  }

  // Check if notification access is granted
  Future<bool> hasNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod('hasNotificationAccess');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  // Start listening for notifications
  Future<void> startListening() async {
    if (_isListening) return;

    final hasPermission = await hasNotificationPermission();
    if (!hasPermission) {
      throw Exception('Notification access permission denied');
    }

    _isListening = true;

    // Start batch processing timer
    _startBatchProcessing();

    try {
      await _channel.invokeMethod('startListening');
      print('Notification listener started');
    } catch (e) {
      print('Failed to start notification listener: $e');
      _isListening = false;
    }
  }

  // Stop listening for notifications
  Future<void> stopListening() async {
    _isListening = false;
    _batchTimer?.cancel();

    try {
      await _channel.invokeMethod('stopListening');
    } catch (e) {
      print('Failed to stop notification listener: $e');
    }
  }

  // Handle received notification
  Future<void> _handleNotificationReceived(Map<dynamic, dynamic> args) async {
    if (!_isListening) return;

    try {
      final notification = NotificationData(
        appPackage: args['packageName'] ?? '',
        title: args['title'] ?? '',
        content: args['text'] ?? '',
        priority: _mapPriority(args['priority']),
        category: args['category'],
        timestamp: DateTime.now(),
      );

      // Add to pending batch
      _pendingNotifications.add(notification);

      // Send immediately if high priority
      if (notification.priority >= 4) {
        await _sendImmediateNotification(notification);
      }
    } catch (e) {
      print('Failed to handle notification: $e');
    }
  }

  // Handle notification removal
  Future<void> _handleNotificationRemoved(Map<dynamic, dynamic> args) async {
    // Optional: handle notification dismissal
  }

  // Map Android priority to our 1-5 scale
  int _mapPriority(dynamic androidPriority) {
    if (androidPriority == null) return 3;

    // Android PRIORITY_HIGH = 1, PRIORITY_DEFAULT = 0, etc.
    switch (androidPriority) {
      case 2:
        return 5; // PRIORITY_MAX
      case 1:
        return 4; // PRIORITY_HIGH
      case 0:
        return 3; // PRIORITY_DEFAULT
      case -1:
        return 2; // PRIORITY_LOW
      case -2:
        return 1; // PRIORITY_MIN
      default:
        return 3;
    }
  }

  // Start batch processing of notifications
  void _startBatchProcessing() {
    _batchTimer = Timer.periodic(
      const Duration(seconds: AppConfig.notificationBatchIntervalSeconds),
      (timer) async {
        if (!_isListening) {
          timer.cancel();
          return;
        }

        await _processPendingNotifications();
      },
    );
  }

  // Process pending notifications in batch
  Future<void> _processPendingNotifications() async {
    if (_pendingNotifications.isEmpty) return;

    // Take up to batch size notifications
    final batchSize = AppConfig.notificationBatchSize;
    final batch = _pendingNotifications.take(batchSize).toList();
    _pendingNotifications.removeRange(
      0,
      batch.length.clamp(0, _pendingNotifications.length),
    );

    try {
      await _apiService.batchSendNotifications(batch);
      print('Sent batch of ${batch.length} notifications');
    } catch (e) {
      print('Failed to send notification batch: $e');

      // Add back to pending list
      _pendingNotifications.insertAll(0, batch);
    }
  }

  // Send high priority notification immediately
  Future<void> _sendImmediateNotification(NotificationData notification) async {
    try {
      await _apiService.sendNotification(
        appPackage: notification.appPackage,
        title: notification.title,
        content: notification.content,
        priority: notification.priority,
        category: notification.category,
      );

      // Remove from pending if successfully sent
      _pendingNotifications.removeWhere(
        (n) =>
            n.title == notification.title &&
            n.timestamp == notification.timestamp,
      );
    } catch (e) {
      print('Failed to send immediate notification: $e');
    }
  }

  // Get notification statistics
  Future<Map<String, int>> getNotificationStats() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];

    return {
      'today': prefs.getInt('notifications_$today') ?? 0,
      'pending': _pendingNotifications.length,
    };
  }

  void dispose() {
    _batchTimer?.cancel();
    stopListening();
  }
}
