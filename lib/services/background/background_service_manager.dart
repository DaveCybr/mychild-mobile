// services/background/background_service_manager.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'screen_monitor_service.dart';
import '../local/local_storage_service.dart';
import 'dart:developer' as developer;

@pragma('vm:entry-point')
class BackgroundServiceManager {
  static const String _tag = 'BackgroundServiceManager';

  /// STEP 1: Initialize (configure only, don't start)
  static Future<void> initializeService() async {
    developer.log('Initializing background service configuration', name: _tag);

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, // Don't auto-start
        isForegroundMode: true,
        notificationChannelId: 'child_app_background',
        initialNotificationTitle: 'Family Safety',
        initialNotificationContent: 'Initializing...',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    developer.log('Background service configured successfully', name: _tag);
  }

  /// STEP 2: Service entry point (CRITICAL: proper timing for foreground)
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    developer.log('========================================', name: _tag);
    developer.log('SERVICE STARTING', name: _tag);
    developer.log('========================================', name: _tag);

    // CRITICAL STEP 1: Register plugins immediately
    DartPluginRegistrant.ensureInitialized();
    developer.log('✅ Plugins registered', name: _tag);

    if (service is AndroidServiceInstance) {
      try {
        developer.log(
          '🔧 Setting up Android foreground service...',
          name: _tag,
        );

        // CRITICAL STEP 2: Set notification info BEFORE promoting to foreground
        await service.setForegroundNotificationInfo(
          title: "Family Safety",
          content: "Initializing service...",
        );
        developer.log('✅ Notification info set', name: _tag);

        // CRITICAL STEP 3: Promote to foreground (NOW safe because notification exists)
        service.setAsForegroundService();
        developer.log('✅ Promoted to foreground service', name: _tag);

        // CRITICAL STEP 4: Small delay for stability
        await Future.delayed(const Duration(milliseconds: 400));

        // STEP 5: Initialize storage
        developer.log('📦 Initializing local storage...', name: _tag);
        await LocalStorageService.init();
        final isPaired = await LocalStorageService.getIsPaired();
        developer.log('Pairing status: $isPaired', name: _tag);

        // STEP 6: Update notification based on status
        await service.setForegroundNotificationInfo(
          title: "Family Safety",
          content: isPaired ? "Monitoring active" : "Ready",
        );
        developer.log('✅ Notification updated', name: _tag);

        // STEP 7: Start monitoring services if paired
        if (isPaired) {
          developer.log('🚀 Starting monitoring services...', name: _tag);

          LocationService.startTracking();
          developer.log('  ✅ Location tracking started', name: _tag);

          NotificationService.startListening();
          developer.log('  ✅ Notification listening started', name: _tag);

          ScreenMonitorService.startMonitoring();
          developer.log('  ✅ Screen monitoring started', name: _tag);

          developer.log('✅ All monitoring services started', name: _tag);
        } else {
          developer.log(
            '⏭️ Device not paired, monitoring services not started',
            name: _tag,
          );
        }
      } catch (e, stackTrace) {
        developer.log(
          '❌ CRITICAL ERROR during service initialization',
          name: _tag,
          error: e,
          stackTrace: stackTrace,
          level: 1000,
        );

        // Stop service on critical error
        developer.log('Stopping service due to error', name: _tag);
        service.stopSelf();
        return;
      }
    }

    // STEP 8: Setup event listeners
    developer.log('Setting up event listeners...', name: _tag);

    service.on('stopService').listen((event) {
      developer.log('Stop command received', name: _tag);
      LocationService.stopTracking();
      NotificationService.stopListening();
      ScreenMonitorService.stopMonitoring();
      service.stopSelf();
    });

    service.on('refreshStatus').listen((event) {
      developer.log('Refresh status command received', name: _tag);
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Family Safety",
          content:
              "Status refreshed at ${DateTime.now().toString().substring(11, 19)}",
        );
      }
    });

    // STEP 9: Keep-alive timer
    developer.log('Starting keep-alive timer...', name: _tag);
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (service is AndroidServiceInstance) {
        try {
          if (await service.isForegroundService()) {
            final now = DateTime.now();
            service.setForegroundNotificationInfo(
              title: "Family Safety Active",
              content:
                  "Last update: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
            );

            developer.log('Heartbeat: Service still active', name: _tag);
          } else {
            developer.log(
              'Service no longer foreground, stopping timer',
              name: _tag,
            );
            timer.cancel();
          }
        } catch (e) {
          developer.log('Error in heartbeat timer', name: _tag, error: e);
          timer.cancel();
        }
      }
    });

    developer.log('========================================', name: _tag);
    developer.log('✅ SERVICE FULLY INITIALIZED', name: _tag);
    developer.log('========================================', name: _tag);
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    developer.log('iOS background mode', name: _tag);
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// STEP 3: Start service (call this after pairing)
  static void startBackgroundServices() {
    developer.log('Starting background service...', name: _tag);
    final service = FlutterBackgroundService();
    service.startService();
    developer.log('Start command sent', name: _tag);
  }

  /// Stop all background services
  static void stopBackgroundServices() {
    developer.log('Stopping background service...', name: _tag);
    final service = FlutterBackgroundService();
    service.invoke("stopService");
    developer.log('Stop command sent', name: _tag);
  }

  /// Check if service is running
  static Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  /// Refresh service status
  static void refreshServiceStatus() {
    developer.log('Refreshing service status...', name: _tag);
    final service = FlutterBackgroundService();
    service.invoke("refreshStatus");
  }
}
