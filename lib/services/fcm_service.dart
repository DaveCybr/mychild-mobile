import 'package:couple_guard_child/services/device_service.dart';
import 'package:couple_guard_child/utils/local_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;

/// Background message handler - MUST be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log('========================================');
  developer.log('📩 Background message received');
  developer.log('Message ID: ${message.messageId}');
  developer.log('Title: ${message.notification?.title}');
  developer.log('Body: ${message.notification?.body}');
  developer.log('Data: ${message.data}');
  developer.log('========================================');
}

class FcmHandler {
  static const String _tag = 'FcmHandler';
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM
  static Future<void> initialize() async {
    try {
      developer.log('🚀 Initializing FCM...', name: _tag);

      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      developer.log(
        'FCM Permission status: ${settings.authorizationStatus}',
        name: _tag,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        developer.log('✅ FCM Permission granted', name: _tag);
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        developer.log('✅ FCM Provisional permission granted', name: _tag);
      } else {
        developer.log('⚠️ FCM Permission denied', name: _tag);
        return;
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        developer.log(
          '✅ FCM Token obtained: ${token.substring(0, 20)}...',
          name: _tag,
        );
        await LocalStorageService.saveFcmToken(token);

        // Send to server if device is paired
        final isPaired = await LocalStorageService.getIsPaired();
        if (isPaired) {
          try {
            final deviceService = Get.find<DeviceService>();
            await deviceService.updateFcmToken(token);
            developer.log('✅ FCM token sent to server', name: _tag);
          } catch (e) {
            developer.log(
              '⚠️ Failed to send FCM token to server',
              name: _tag,
              error: e,
            );
          }
        }
      } else {
        developer.log('❌ Failed to get FCM token', name: _tag);
      }

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        developer.log(
          '🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...',
          name: _tag,
        );
        await LocalStorageService.saveFcmToken(newToken);

        // Send to server
        final isPaired = await LocalStorageService.getIsPaired();
        if (isPaired) {
          try {
            final deviceService = Get.find<DeviceService>();
            await deviceService.updateFcmToken(newToken);
            developer.log('✅ New FCM token sent to server', name: _tag);
          } catch (e) {
            developer.log(
              '⚠️ Failed to send new FCM token',
              name: _tag,
              error: e,
            );
          }
        }
      });

      // Configure foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Configure message opened handler
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        developer.log('📬 App opened from notification', name: _tag);
        _handleMessageOpenedApp(initialMessage);
      }

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      developer.log('✅ FCM initialized successfully', name: _tag);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to initialize FCM',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    developer.log('✅ Local notifications initialized', name: _tag);
  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    developer.log('========================================', name: _tag);
    developer.log('📩 Foreground message received', name: _tag);
    developer.log('Message ID: ${message.messageId}', name: _tag);

    if (message.notification != null) {
      developer.log('Title: ${message.notification!.title}', name: _tag);
      developer.log('Body: ${message.notification!.body}', name: _tag);

      // Show local notification
      await _showLocalNotification(message);
    }

    if (message.data.isNotEmpty) {
      developer.log('Data: ${message.data}', name: _tag);
      _handleNotificationData(message.data);
    }

    developer.log('========================================', name: _tag);
  }

  /// Handle message opened from notification
  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    developer.log('========================================', name: _tag);
    developer.log('📬 Notification opened', name: _tag);
    developer.log('Message ID: ${message.messageId}', name: _tag);

    if (message.data.isNotEmpty) {
      developer.log('Data: ${message.data}', name: _tag);
      _handleNotificationData(message.data);
    }

    developer.log('========================================', name: _tag);
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    developer.log('🔔 Notification tapped', name: _tag);
    developer.log('Payload: ${response.payload}', name: _tag);

    // Handle navigation based on payload
    if (response.payload != null && response.payload!.isNotEmpty) {
      // You can navigate to specific screens here
      // Example: Get.toNamed('/location');
    }
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        showWhen: true,
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Pika',
        message.notification?.body ?? 'You have a new message',
        details,
        payload: message.data.toString(),
      );

      developer.log('✅ Local notification shown', name: _tag);
    } catch (e) {
      developer.log(
        '❌ Failed to show local notification',
        name: _tag,
        error: e,
      );
    }
  }

  /// Handle notification data based on type
  static void _handleNotificationData(Map<String, dynamic> data) {
    try {
      final type = data['type'] as String?;

      developer.log('Handling notification type: $type', name: _tag);

      switch (type) {
        case 'location_request':
          developer.log('📍 Location request notification', name: _tag);
          _handleLocationRequest(data);
          break;

        case 'request_location':
          developer.log('📍 Request location command', name: _tag);
          _handleLocationRequest(data);
          break;

        case 'geofence_alert':
          developer.log('🚨 Geofence alert notification', name: _tag);
          _handleGeofenceAlert(data);
          break;

        case 'battery_alert':
          developer.log('🔋 Battery alert notification', name: _tag);
          _handleBatteryAlert(data);
          break;

        case 'start_monitoring':
          developer.log('▶️ Start monitoring command', name: _tag);
          _handleStartMonitoring(data);
          break;

        case 'stop_monitoring':
          developer.log('⏸️ Stop monitoring command', name: _tag);
          _handleStopMonitoring(data);
          break;

        default:
          developer.log('ℹ️ General notification', name: _tag);
          break;
      }
    } catch (e) {
      developer.log('❌ Error handling notification data', name: _tag, error: e);
    }
  }

  /// Handle location request
  static void _handleLocationRequest(Map<String, dynamic> data) {
    developer.log('Processing location request...', name: _tag);

    // Trigger immediate location update via Native Bridge
    // The native service will handle this automatically
    // Just show a notification to user
    _showLocalNotificationCustom(
      title: 'Location Requested',
      body: 'Your parent requested your current location',
    );
  }

  /// Handle geofence alert
  static void _handleGeofenceAlert(Map<String, dynamic> data) {
    developer.log('Processing geofence alert...', name: _tag);

    final message = data['message'] as String? ?? 'Geofence alert';

    _showLocalNotificationCustom(title: 'Location Alert', body: message);
  }

  /// Handle battery alert
  static void _handleBatteryAlert(Map<String, dynamic> data) {
    developer.log('Processing battery alert...', name: _tag);

    _showLocalNotificationCustom(
      title: 'Battery Low',
      body: 'Please charge your device',
    );
  }

  /// Handle start monitoring
  static void _handleStartMonitoring(Map<String, dynamic> data) {
    developer.log('Starting monitoring...', name: _tag);

    // Services should already be running, just confirm
    _showLocalNotificationCustom(
      title: 'Monitoring Active',
      body: 'Location tracking is now active',
    );
  }

  /// Handle stop monitoring
  static void _handleStopMonitoring(Map<String, dynamic> data) {
    developer.log('Stopping monitoring...', name: _tag);

    _showLocalNotificationCustom(
      title: 'Monitoring Paused',
      body: 'Location tracking is paused',
    );
  }

  /// Show custom local notification
  static Future<void> _showLocalNotificationCustom({
    required String title,
    required String body,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    } catch (e) {
      developer.log('Error showing notification', name: _tag, error: e);
    }
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await LocalStorageService.saveFcmToken(token);
      }
      return token;
    } catch (e) {
      developer.log('Error getting FCM token', name: _tag, error: e);
      return null;
    }
  }

  /// Check if FCM token exists
  static Future<bool> hasToken() async {
    final token = await LocalStorageService.getFcmToken();
    return token != null && token.isNotEmpty;
  }

  /// Delete FCM token
  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      await LocalStorageService.saveFcmToken('');
      developer.log('✅ FCM token deleted', name: _tag);
    } catch (e) {
      developer.log('❌ Failed to delete FCM token', name: _tag, error: e);
    }
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      developer.log('✅ Subscribed to topic: $topic', name: _tag);
    } catch (e) {
      developer.log('❌ Failed to subscribe to topic', name: _tag, error: e);
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      developer.log('✅ Unsubscribed from topic: $topic', name: _tag);
    } catch (e) {
      developer.log('❌ Failed to unsubscribe from topic', name: _tag, error: e);
    }
  }

  /// Request permission (for iOS or Android 13+)
  static Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      developer.log('Error requesting permission', name: _tag, error: e);
      return false;
    }
  }

  /// Check notification permission status
  static Future<bool> isPermissionGranted() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      developer.log('Error checking permission', name: _tag, error: e);
      return false;
    }
  }
}
