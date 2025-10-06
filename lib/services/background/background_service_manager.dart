// services/background/background_service_manager.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

import 'location_service.dart';
import 'notification_service.dart';
import 'screen_monitor_service.dart';
import '../local/local_storage_service.dart';

// 🔹 Entry-point utama agar dikenali di build AOT
@pragma('vm:entry-point')
void backgroundMain(ServiceInstance service) {
  BackgroundServiceManager.onStart(service);
}

// 🔹 Class utama background manager
@pragma('vm:entry-point')
class BackgroundServiceManager {
  static const String _tag = 'BackgroundServiceManager';

  // 🔹 Konfigurasi awal service
  @pragma('vm:entry-point')
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: backgroundMain, // gunakan alias global
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

  // 🔹 Callback utama saat service dimulai
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    developer.log('🚀 Background Service onStart() called', name: _tag);

    if (service is AndroidServiceInstance) {
      try {
        // // 🔴 PENTING: langsung set foreground service & notification
        // // agar Android tidak melempar ForegroundServiceDidNotStartInTimeException
        // await service.setAsForegroundService();
        // await service.setForegroundNotificationInfo(
        //   title: "Family Safety",
        //   content: "Starting monitoring...",
        // );
        service.on('setAsForeground').listen((event) {
          service.setAsForegroundService();
        });

        service.setForegroundNotificationInfo(
          title: "Ciko is running",
          content: "Monitoring child activity...",
        );
        developer.log('✅ Foreground service started', name: _tag);
      } catch (e) {
        developer.log(
          '❌ Failed to set foreground service quickly: $e',
          name: _tag,
        );
        // jika gagal, hentikan agar tidak crash lebih jauh
        return;
      }
    }

    // Register listeners (non-blocking)
    service.on('stopService').listen((event) async {
      developer.log('🛑 Stop service requested', name: _tag);
      _cleanupServices();
      service.stopSelf();
    });

    service.on('setAsForeground').listen((event) {
      if (service is AndroidServiceInstance) service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      if (service is AndroidServiceInstance) service.setAsBackgroundService();
    });

    // 🔸 Pindahkan semua init berat ke fungsi async terpisah agar tidak menunda setForeground
    Future.microtask(() => _initializeAsync(service));
  }

  // 🔹 Inisialisasi async
  @pragma('vm:entry-point')
  static Future<void> _initializeAsync(ServiceInstance service) async {
    try {
      developer.log('Initializing local storage...', name: _tag);
      await LocalStorageService.init();
      developer.log('✅ Storage initialized', name: _tag);

      final isPaired = await LocalStorageService.getIsPaired();
      developer.log('Device paired: $isPaired', name: _tag);

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Family Safety",
          content: isPaired ? "Initializing..." : "Ready to pair",
        );
      }

      if (isPaired) {
        developer.log('Starting monitoring services...', name: _tag);
        await _startMonitoringServices();

        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "Family Safety Active",
            content: "Monitoring in progress",
          );
        }

        _startHeartbeat(service);
      }
    } catch (e, st) {
      developer.log(
        '❌ Error in async init: $e',
        name: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  // 🔹 Start monitoring tasks
  @pragma('vm:entry-point')
  static Future<void> _startMonitoringServices() async {
    final List<Future<void>> tasks = [];

    tasks.add(
      Future(() async {
        try {
          LocationService.startTracking();
          developer.log('✅ Location tracking started', name: _tag);
        } catch (e) {
          developer.log('⚠️ Failed to start location tracking: $e', name: _tag);
        }
      }),
    );

    tasks.add(
      Future(() async {
        try {
          NotificationService.startListening();
          developer.log('✅ Notification listening started', name: _tag);
        } catch (e) {
          developer.log(
            '⚠️ Failed to start notification listening: $e',
            name: _tag,
          );
        }
      }),
    );

    tasks.add(
      Future(() async {
        try {
          ScreenMonitorService.startMonitoring();
          developer.log('✅ Screen monitoring started', name: _tag);
        } catch (e) {
          developer.log('⚠️ Failed to start screen monitoring: $e', name: _tag);
        }
      }),
    );

    await Future.wait(tasks);
  }

  // 🔹 Heartbeat untuk update notifikasi setiap 30 detik
  @pragma('vm:entry-point')
  static void _startHeartbeat(ServiceInstance service) {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        if (service is AndroidServiceInstance) {
          if (await service.isForegroundService()) {
            final now = DateTime.now();
            service.setForegroundNotificationInfo(
              title: "Family Safety Active",
              content:
                  "Last update: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
            );

            try {
              service.invoke('heartbeat');
            } catch (e) {
              developer.log('⚠️ Heartbeat invoke failed: $e', name: _tag);
            }
          } else {
            timer.cancel();
            developer.log(
              '⏹️ Service no longer foreground — stopping heartbeat',
              name: _tag,
            );
          }
        }
      } catch (e, st) {
        developer.log(
          '❌ Error in heartbeat: $e',
          name: _tag,
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  // 🔹 Cleanup service
  @pragma('vm:entry-point')
  static void _cleanupServices() {
    try {
      LocationService.stopTracking();
      NotificationService.stopListening();
      ScreenMonitorService.stopMonitoring();
      developer.log('✅ All services cleaned up', name: _tag);
    } catch (e) {
      developer.log('❌ Error cleaning up services: $e', name: _tag);
    }
  }

  // 🔹 Callback iOS
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  // 🔹 Public API (tidak butuh annotation)
  static void startBackgroundServices() {
    try {
      developer.log('Starting background service', name: _tag);
      final service = FlutterBackgroundService();
      service.startService();
    } catch (e) {
      developer.log('Failed to start service', name: _tag, error: e);
    }
  }

  static void stopBackgroundServices() {
    try {
      developer.log('Stopping background service', name: _tag);
      final service = FlutterBackgroundService();
      service.invoke("stopService");
    } catch (e) {
      developer.log('Failed to stop service', name: _tag, error: e);
    }
  }

  static Future<bool> isServiceRunning() async {
    try {
      final service = FlutterBackgroundService();
      return await service.isRunning();
    } catch (e) {
      developer.log('Failed to check service status', name: _tag, error: e);
      return false;
    }
  }
}
