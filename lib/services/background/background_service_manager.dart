// services/background/background_service_manager.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'screen_monitor_service.dart';
import '../local/local_storage_service.dart';

class BackgroundServiceManager {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'child_app_background',
        initialNotificationTitle: 'Family Safety',
        initialNotificationContent: 'Keeping you connected',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) {
    // CRITICAL: Set foreground FIRST - synchronous, no await
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    // Register plugins immediately after
    DartPluginRegistrant.ensureInitialized();

    // Setup event listeners
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Schedule async initialization AFTER foreground is set
    Future.microtask(() => _initializeAsync(service));
  }

  static Future<void> _initializeAsync(ServiceInstance service) async {
    try {
      // Now safe to do async operations
      await LocalStorageService.init();
      final isPaired = await LocalStorageService.getIsPaired();

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Family Safety",
          content: isPaired ? "Monitoring active" : "Ready",
        );
      }

      if (isPaired) {
        // Start monitoring services
        LocationService.startTracking();
        NotificationService.startListening();
        ScreenMonitorService.startMonitoring();

        // Keep alive timer
        Timer.periodic(const Duration(seconds: 30), (timer) async {
          if (service is AndroidServiceInstance) {
            if (await service.isForegroundService()) {
              final now = DateTime.now();
              service.setForegroundNotificationInfo(
                title: "Family Safety Active",
                content:
                    "Last update: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
              );
            } else {
              timer.cancel();
              return;
            }
          }

          service.invoke('heartbeat');
        });
      }
    } catch (e) {
      print('Background service initialization error: $e');
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Family Safety",
          content: "Service running (error: $e)",
        );
      }
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  static void startBackgroundServices() {
    final service = FlutterBackgroundService();
    service.startService();
  }

  static void stopBackgroundServices() {
    final service = FlutterBackgroundService();
    service.invoke("stopService");
  }
}
