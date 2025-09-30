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
  // Initialize ONLY configures, does NOT start service
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, // Changed to false - start manually
        isForegroundMode: true,
        notificationChannelId: 'child_app_background',
        initialNotificationTitle: 'Family Safety',
        initialNotificationContent: 'Keeping you connected',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false, // Changed to false
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) {
    // STEP 1: Set foreground IMMEDIATELY
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    // STEP 2: Register plugins
    DartPluginRegistrant.ensureInitialized();

    // STEP 3: Setup event listeners
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

    // STEP 4: Initialize async work
    Future.microtask(() => _initializeAsync(service));
  }

  static Future<void> _initializeAsync(ServiceInstance service) async {
    try {
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
          content: "Service running",
        );
      }
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  // Call this AFTER pairing is complete
  static void startBackgroundServices() {
    final service = FlutterBackgroundService();
    service.startService();
  }

  static void stopBackgroundServices() {
    final service = FlutterBackgroundService();
    service.invoke("stopService");
  }
}
