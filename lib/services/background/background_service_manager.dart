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
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'child_app_background',
        initialNotificationTitle: 'Family Safety',
        initialNotificationContent: 'Keeping you connected',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) {
    // CRITICAL: Set foreground IMMEDIATELY before any async operations
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      // Call startForeground IMMEDIATELY (within 5 seconds requirement)
      service.setAsForegroundService();

      // Set initial notification right away
      service.setForegroundNotificationInfo(
        title: "Family Safety",
        content: "Starting monitoring services...",
      );
    }

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
      LocationService.stopTracking();
      NotificationService.stopListening();
      ScreenMonitorService.stopMonitoring();
      service.stopSelf();
    });

    // Now do async initialization in background
    _initializeAsync(service).catchError((error) {
      print('Background service initialization error: $error');
      // Keep service running even if initialization fails
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Family Safety",
          content: "Service running (initialization failed)",
        );
      }
    });
  }

  static Future<void> _initializeAsync(ServiceInstance service) async {
    try {
      // Initialize local storage
      await LocalStorageService.init();

      final isPaired = await LocalStorageService.getIsPaired();

      // Update notification after checking pairing status
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Family Safety",
          content: isPaired ? "Monitoring active" : "Ready to pair",
        );
      }

      if (isPaired) {
        // Start monitoring services with error handling
        try {
          LocationService.startTracking();
          print('✓ Location tracking started');
        } catch (e) {
          print('Failed to start location tracking: $e');
        }

        try {
          NotificationService.startListening();
          print('✓ Notification listening started');
        } catch (e) {
          print('Failed to start notification listening: $e');
        }

        try {
          ScreenMonitorService.startMonitoring();
          print('✓ Screen monitoring started');
        } catch (e) {
          print('Failed to start screen monitoring: $e');
        }

        // Update notification when all services started
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "Family Safety Active",
            content: "All monitoring services running",
          );
        }

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
      // Still show service is running
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
    try {
      final service = FlutterBackgroundService();
      service.startService();
      print('✓ Background service started');
    } catch (e) {
      print('Failed to start background service: $e');
    }
  }

  static void stopBackgroundServices() {
    try {
      final service = FlutterBackgroundService();
      service.invoke("stopService");
      print('✓ Background service stopped');
    } catch (e) {
      print('Failed to stop background service: $e');
    }
  }

  // Check if service is running
  static Future<bool> isServiceRunning() async {
    try {
      final service = FlutterBackgroundService();
      return await service.isRunning();
    } catch (e) {
      print('Failed to check service status: $e');
      return false;
    }
  }
}
