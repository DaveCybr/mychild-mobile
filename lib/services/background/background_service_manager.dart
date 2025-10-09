// services/background/background_service_manager.dart - FIXED
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:developer' as developer;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

import 'location_service.dart';
import 'notification_service.dart';
import 'screen_monitor_service.dart';
import '../local/local_storage_service.dart';

@pragma('vm:entry-point')
class BackgroundServiceManager {
  static const String _tag = 'BackgroundServiceManager';

  /// STEP 1: Initialize configuration (only called once in main.dart)
  static Future<void> initializeService() async {
    developer.log(
      'Initializing background service configuration...',
      name: _tag,
    );

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'child_app_background',
        initialNotificationTitle: 'Family Safety',
        initialNotificationContent: 'Service is starting...',
        foregroundServiceNotificationId: 1001,
        foregroundServiceTypes: [
          AndroidForegroundType.location,
          AndroidForegroundType.dataSync,
        ],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    developer.log('✅ Service configuration complete', name: _tag);
  }

  /// STEP 2: Service entry point (executed in background isolate)
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    developer.log('-----------------------------------------', name: _tag);
    developer.log('🚀 SERVICE STARTING', name: _tag);
    developer.log('-----------------------------------------', name: _tag);

    // ✅ CRITICAL: Ensure plugin registration for background isolate
    DartPluginRegistrant.ensureInitialized();

    // ✅ FIX: Only use AndroidServiceInstance methods in background isolate
    if (service is AndroidServiceInstance) {
      try {
        developer.log('Platform: Android ${Platform.version}', name: _tag);

        // Delay for system stability
        await Future.delayed(const Duration(milliseconds: 1500));

        // Set initial notification
        await service.setForegroundNotificationInfo(
          title: "Family Safety",
          content: "Initializing service...",
        );

        await Future.delayed(const Duration(milliseconds: 1500));

        // Set as foreground service
        await service.setAsForegroundService();
        developer.log('✅ Foreground service STARTED', name: _tag);

        // Initialize local storage IN BACKGROUND ISOLATE
        await LocalStorageService.init();
        final isPaired = await LocalStorageService.getIsPaired();
        developer.log('Pairing status: $isPaired', name: _tag);

        // Update notification
        await service.setForegroundNotificationInfo(
          title: "Family Safety",
          content: isPaired ? "Monitoring active" : "Ready to pair",
        );

        // Start background tasks (only if paired)
        if (isPaired) {
          developer.log(
            'Starting background monitoring modules...',
            name: _tag,
          );

          try {
            LocationService.startTracking();
            developer.log('✅ Location tracking started', name: _tag);
          } catch (e) {
            developer.log('❌ Location tracking failed: $e', name: _tag);
          }

          // ⚠️ FIX: NotificationService should NOT be started in background isolate
          // It needs main isolate for MethodChannel
          developer.log(
            '⚠️ Notification listener started (via main isolate)',
            name: _tag,
          );

          try {
            ScreenMonitorService.startMonitoring();
            developer.log('✅ Screen monitoring started', name: _tag);
          } catch (e) {
            developer.log('❌ Screen monitoring failed: $e', name: _tag);
          }

          developer.log('✅ All background modules started', name: _tag);
        } else {
          developer.log(
            '⏭️ Device not paired — background modules skipped',
            name: _tag,
          );
        }
      } catch (e, stack) {
        developer.log(
          '❌ CRITICAL: Failed to start background service',
          name: _tag,
          error: e,
          stackTrace: stack,
          level: 1000,
        );
      }
    }

    // Event listeners
    service.on('stopService').listen((event) async {
      developer.log('🛑 Stop command received', name: _tag);
      try {
        LocationService.stopTracking();
        NotificationService.stopListening();
        ScreenMonitorService.stopMonitoring();
      } catch (e) {
        developer.log('Error while stopping services: $e', name: _tag);
      }
      await service.stopSelf();
    });

    service.on('refreshStatus').listen((event) async {
      if (service is AndroidServiceInstance) {
        await service.setForegroundNotificationInfo(
          title: "Family Safety",
          content:
              "Refreshed at ${DateTime.now().toLocal().toIso8601String().substring(11, 19)}",
        );
      }
    });

    // Heartbeat
    Timer.periodic(const Duration(seconds: 60), (timer) async {
      if (service is AndroidServiceInstance) {
        try {
          if (await service.isForegroundService()) {
            final now = DateTime.now();
            await service.setForegroundNotificationInfo(
              title: "Family Safety Active",
              content:
                  "Last check: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
            );
            developer.log('💓 Heartbeat OK', name: _tag);
          } else {
            timer.cancel();
          }
        } catch (e) {
          developer.log('❌ Heartbeat error: $e', name: _tag);
          timer.cancel();
        }
      }
    });

    developer.log('✅ SERVICE FULLY INITIALIZED', name: _tag);
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    developer.log('Running iOS background mode', name: _tag);
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  static Future<void> startBackgroundServices() async {
    developer.log('▶️ Starting background service...', name: _tag);

    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();

      if (isRunning) {
        developer.log('⚠️ Service already running', name: _tag);
        return;
      }

      await service.startService();
      developer.log('✅ Background service start command sent', name: _tag);

      await Future.delayed(const Duration(seconds: 3));
      final nowRunning = await service.isRunning();
      developer.log('Service running status: $nowRunning', name: _tag);
    } catch (e, stack) {
      developer.log(
        '❌ Failed to start service',
        name: _tag,
        error: e,
        stackTrace: stack,
        level: 1000,
      );
    }
  }

  static Future<void> stopBackgroundServices() async {
    developer.log('⏹️ Stopping background service...', name: _tag);
    final service = FlutterBackgroundService();
    service.invoke("stopService");
    developer.log('✅ Background service stop command sent', name: _tag);
  }

  static Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  static void refreshServiceStatus() {
    developer.log('🔄 Refreshing service notification...', name: _tag);
    final service = FlutterBackgroundService();
    service.invoke("refreshStatus");
  }
}
