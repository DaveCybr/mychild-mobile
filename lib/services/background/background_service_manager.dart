// services/background/background_service_manager.dart
import 'dart:async';
// import 'dart:io';
import 'dart:ui';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

// import 'notification_service.dart';
import '../local/local_storage_service.dart';

@pragma('vm:entry-point')
class BackgroundServiceManager {
  static const String _tag = 'BackgroundServiceManager';
  static const _platform = MethodChannel('location_worker_channel');

  static Future<void> initializeService() async {
    developer.log('Initializing background service...', name: _tag);

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
        autoStartOnBoot: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    developer.log('✅ Service configuration complete', name: _tag);
  }

  // background_service_manager.dart
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    developer.log('🚀 SERVICE STARTING', name: _tag);

    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      try {
        await Future.delayed(const Duration(milliseconds: 1500));

        await service.setForegroundNotificationInfo(
          title: "Family Safety",
          content: "Initializing...",
        );

        await service.setAsForegroundService();
        developer.log('✅ Foreground service started', name: _tag);

        await LocalStorageService.init();
        final isPaired = await LocalStorageService.getIsPaired();

        developer.log('Pairing status: $isPaired', name: _tag);

        if (isPaired) {
          // ✅ Pastikan WorkManager + Watchdog running
          try {
            await _platform.invokeMethod('startPeriodicLocation');
            developer.log('✅ WorkManager scheduled from service', name: _tag);
          } catch (e) {
            developer.log(
              'Failed to schedule WorkManager',
              name: _tag,
              error: e,
            );
          }

          await service.setForegroundNotificationInfo(
            title: "Family Safety Active",
            content: "All monitoring services running",
          );
        } else {
          await service.setForegroundNotificationInfo(
            title: "Family Safety",
            content: "Ready to pair",
          );
        }
      } catch (e, stack) {
        developer.log(
          'Failed to start service',
          name: _tag,
          error: e,
          stackTrace: stack,
          level: 1000,
        );
      }
    }

    // ✨ Enhanced heartbeat dengan status update
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (service is AndroidServiceInstance) {
        try {
          if (await service.isForegroundService()) {
            final now = DateTime.now();

            // Send heartbeat to server
            try {
              final deviceId = await LocalStorageService.getDeviceId();
              if (deviceId != null) {
                // Call native method untuk update status
                await _platform.invokeMethod('sendHeartbeat');
              }
            } catch (e) {
              developer.log('Heartbeat failed', name: _tag, error: e);
            }

            await service.setForegroundNotificationInfo(
              title: "Family Safety Active",
              content:
                  "Last check: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
            );
          } else {
            timer.cancel();
          }
        } catch (e) {
          timer.cancel();
        }
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  static Future<void> startBackgroundServices() async {
    developer.log('▶️ Starting background services...', name: _tag);

    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();

      if (isRunning) {
        developer.log('⚠️ Service already running', name: _tag);
        return;
      }

      await service.startService();
      developer.log('✅ Service started', name: _tag);
    } catch (e) {
      developer.log(
        'Failed to start service',
        name: _tag,
        error: e,
        level: 1000,
      );
    }
  }

  static Future<void> stopBackgroundServices() async {
    developer.log('⏹️ Stopping services...', name: _tag);

    // Cancel WorkManager
    try {
      await _platform.invokeMethod('stopPeriodicLocation');
    } catch (e) {
      developer.log('Failed to stop location worker', name: _tag, error: e);
    }

    final service = FlutterBackgroundService();
    service.invoke("stopService");
  }

  static Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}
