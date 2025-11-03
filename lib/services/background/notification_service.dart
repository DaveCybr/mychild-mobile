// services/background/notification_service.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;
import '../../core/constants/app_endpoints.dart';
import '../api/api_service.dart';
import '../local/local_storage_service.dart';

class NotificationService {
  static const String _tag = 'NotificationService';
  static const MethodChannel _channel = MethodChannel(
    'notification_listener_channel',
  );

  static bool _isListening = false;
  static StreamSubscription? _subscription;

  static Future<void> startListening() async {
    if (_isListening) {
      developer.log('Already listening, skipping', name: _tag);
      return;
    }

    developer.log('========================================', name: _tag);
    developer.log('STARTING NOTIFICATION LISTENER', name: _tag);

    try {
      // Skip ini di background isolate
      final hasPermission = await checkPermission();
      developer.log('Permission status: $hasPermission', name: _tag);

      if (!hasPermission) {
        developer.log('⚠️ No notification permission', name: _tag);
        return;
      }

      _channel.setMethodCallHandler(_handleNotificationFromNative);
      developer.log('✅ Method call handler registered', name: _tag);

      _isListening = true;
      developer.log('✅ Notification listener ACTIVE', name: _tag);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to start notification listener',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      _isListening = false;
    }

    developer.log('========================================', name: _tag);
  }

  /// Handle notifications received from native Android
  static Future<void> _handleNotificationFromNative(MethodCall call) async {
    if (call.method == 'onNotificationReceived') {
      try {
        final Map<dynamic, dynamic> args = call.arguments;
        final packageName = args['package']?.toString() ?? '';
        final title = args['title']?.toString() ?? '';
        final text = args['text']?.toString() ?? '';
        final timestamp = args['timestamp']?.toString() ?? '';

        developer.log('📱 Notification from Flutter UI:', name: _tag);
        developer.log('  Package: $packageName', name: _tag);
        developer.log('  Title: $title', name: _tag);
        developer.log(
          '  Text: ${text.length > 50 ? text.substring(0, 50) + "..." : text}',
          name: _tag,
        );
        developer.log('  Timestamp: $timestamp', name: _tag);

        // Note: Server sending is already handled in native code
        // This is just for Flutter-side logging/processing if needed
      } catch (e) {
        developer.log(
          '❌ Error handling notification from native',
          name: _tag,
          error: e,
          level: 900,
        );
      }
    }
  }

  /// Check if notification listener permission is granted
  static Future<bool> checkPermission() async {
    try {
      final result = await _channel.invokeMethod('checkNotificationPermission');
      return result as bool? ?? false;
    } catch (e) {
      developer.log(
        'Error checking permission',
        name: _tag,
        error: e,
        level: 900,
      );
      return false;
    }
  }

  /// Open notification listener settings
  static Future<void> openSettings() async {
    try {
      developer.log('Opening notification settings', name: _tag);
      await _channel.invokeMethod('openNotificationSettings');
    } catch (e) {
      developer.log('Error opening settings', name: _tag, error: e, level: 900);
    }
  }

  /// Manual send notification (for testing or Flutter-side notifications)
  static Future<void> sendNotificationManual({
    required String appName,
    required String title,
    required String content,
  }) async {
    try {
      final deviceId = await LocalStorageService.getDeviceId();
      if (deviceId == null) {
        developer.log('No device ID, cannot send', name: _tag);
        return;
      }

      developer.log('Manually sending notification to server', name: _tag);

      final apiService = ApiService();

      await apiService.post(
        ApiEndpoints.sendNotification,
        data: {
          'device_id': deviceId,
          'app_name': appName,
          'title': title,
          'content': content,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      developer.log('✅ Manual notification sent', name: _tag);
    } catch (e) {
      developer.log(
        '❌ Failed to send manual notification',
        name: _tag,
        error: e,
        level: 900,
      );
    }
  }

  /// Stop listening
  static void stopListening() {
    developer.log('Stopping notification listener', name: _tag);
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    developer.log('✅ Notification listener stopped', name: _tag);
  }

  /// Get listening status
  static bool get isListening => _isListening;
}
