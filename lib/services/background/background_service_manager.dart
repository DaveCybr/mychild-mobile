// services/background/background_service_manager.dart
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
        initialNotificationContent: 'Preparing background service...',
        foregroundServiceNotificationId: 1001,
        foregroundServiceTypes: [AndroidForegroundType.location],
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

    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      try {
        // PENTING: Ensure notification channel exists BEFORE setForegroundNotificationInfo
        if (Platform.isAndroid) {
          // Channel sudah dibuat di MainActivity
          developer.log('Using pre-created notification channel', name: _tag);
        }

        // 🔹 Step 1: Set notification info (jangan langsung setAsForegroundService)
        await service.setForegroundNotificationInfo(
          title: "Family Safety",
          content: "Initializing...",
        );

        // 🔹 Step 2: Delay untuk Android 12+
        await Future.delayed(const Duration(milliseconds: 1200));

        // 🔹 Step 3: Set as foreground
        await service.setAsForegroundService();
        developer.log('✅ Foreground service started', name: _tag);
        // 🔹 Step 4: Initialize local storage
        await LocalStorageService.init();
        final isPaired = await LocalStorageService.getIsPaired();
        developer.log('Pairing status: $isPaired', name: _tag);

        // 🔹 Step 5: Update notification
        await service.setForegroundNotificationInfo(
          title: "Family Safety",
          content: isPaired ? "Monitoring active" : "Ready to pair",
        );

        // 🔹 Step 6: Start background tasks (only if paired)
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

          try {
            await NotificationService.startListening();
            developer.log('✅ Notification listener started', name: _tag);
          } catch (e) {
            developer.log('❌ Notification listener failed: $e', name: _tag);
          }

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
        );
        await service.stopSelf();
        return;
      }
    }

    // 🔹 Step 7: Event listeners
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
      developer.log('🔁 Refresh status command received', name: _tag);
      if (service is AndroidServiceInstance) {
        await service.setForegroundNotificationInfo(
          title: "Family Safety",
          content:
              "Status refreshed at ${DateTime.now().toLocal().toIso8601String()}",
        );
      }
    });

    // 🔹 Step 8: Keep-alive heartbeat (every 30s)
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (service is AndroidServiceInstance) {
        try {
          if (await service.isForegroundService()) {
            final now = DateTime.now();
            await service.setForegroundNotificationInfo(
              title: "Family Safety Active",
              content:
                  "Last heartbeat: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
            );
            developer.log('💓 Heartbeat OK', name: _tag);
          } else {
            developer.log(
              '⚠️ Service not foreground — stopping heartbeat',
              name: _tag,
            );
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

  /// STEP 3: iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    developer.log('Running iOS background mode', name: _tag);
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// STEP 4: Start background service (called after pairing success)
  static Future<void> startBackgroundServices() async {
    developer.log('▶️ Starting background service...', name: _tag);
    final service = FlutterBackgroundService();
    await service.startService();
    developer.log('✅ Background service start command sent', name: _tag);
  }

  /// STEP 5: Stop background service completely
  static Future<void> stopBackgroundServices() async {
    developer.log('⏹️ Stopping background service...', name: _tag);
    final service = FlutterBackgroundService();
    service.invoke("stopService");
    developer.log('✅ Background service stop command sent', name: _tag);
  }

  /// STEP 6: Check if background service is currently running
  static Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  /// STEP 7: Refresh notification info manually
  static void refreshServiceStatus() {
    developer.log('🔄 Refreshing service notification...', name: _tag);
    final service = FlutterBackgroundService();
    service.invoke("refreshStatus");
  }
}
