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
  static Future<void> onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // CRITICAL: Set as foreground IMMEDIATELY for Android
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();

      // Update notification immediately
      service.setForegroundNotificationInfo(
        title: "Family Safety",
        content: "Starting monitoring services...",
      );
    }

    // Setup event listeners AFTER foreground is set
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

    // Initialize services
    try {
      await LocalStorageService.init();
      final isPaired = await LocalStorageService.getIsPaired();

      if (isPaired) {
        // Update notification
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "Family Safety Active",
            content: "Monitoring location and notifications",
          );
        }

        // Start all monitoring services
        LocationService.startTracking();
        NotificationService.startListening();
        ScreenMonitorService.startMonitoring();

        // Keep alive timer
        Timer.periodic(const Duration(seconds: 30), (timer) async {
          if (service is AndroidServiceInstance) {
            if (await service.isForegroundService()) {
              service.setForegroundNotificationInfo(
                title: "Family Safety Active",
                content:
                    "Last check: ${DateTime.now().toString().substring(11, 16)}",
              );
            } else {
              // Service berhenti, cancel timer
              timer.cancel();
              return;
            }
          }

          // Send heartbeat
          service.invoke('heartbeat');
        });
      } else {
        // Belum paired
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "Family Safety",
            content: "Waiting for pairing...",
          );
        }
      }
    } catch (e) {
      print('Error in background service: $e');
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Family Safety",
          content: "Service error, restarting...",
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
