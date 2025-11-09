// services/background/background_service_manager.dart - COMPLETE
import 'dart:async';
import 'dart:ui';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
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
        autoStart: false, // ✅ CRITICAL: Don't auto start!
        isForegroundMode: true,
        notificationChannelId: 'child_app_background',
        initialNotificationTitle: 'Family Safety',
        initialNotificationContent: 'Initializing services...',
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

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    developer.log('========================================', name: _tag);
    developer.log('🚀 SERVICE STARTING', name: _tag);

    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      try {
        // ✅ CRITICAL: Delay 2 seconds untuk ensure notification channel ready
        developer.log('Waiting for notification channel...', name: _tag);
        await Future.delayed(const Duration(milliseconds: 2000));

        // ✅ Set notification dengan content yang proper
        developer.log('Setting foreground notification...', name: _tag);
        await service.setForegroundNotificationInfo(
          title: "Family Safety",
          content: "Initializing services...",
        );

        // ✅ MUST call setAsForegroundService
        developer.log('Setting as foreground service...', name: _tag);
        await service.setAsForegroundService();
        developer.log('✅ Foreground service started', name: _tag);

        // Initialize local storage
        developer.log('Initializing local storage...', name: _tag);
        await LocalStorageService.init();

        final isPaired = await LocalStorageService.getIsPaired();
        developer.log('Pairing status: $isPaired', name: _tag);

        if (isPaired) {
          // Start WorkManager
          try {
            developer.log('Starting WorkManager...', name: _tag);
            await _platform.invokeMethod('startPeriodicLocation');
            developer.log('✅ WorkManager scheduled from service', name: _tag);
          } catch (e) {
            developer.log(
              'Failed to schedule WorkManager',
              name: _tag,
              error: e,
            );
          }

          // Update notification
          await service.setForegroundNotificationInfo(
            title: "Family Safety Active",
            content: "Location tracking and monitoring enabled",
          );
          developer.log('✅ Notification updated for paired device', name: _tag);
        } else {
          await service.setForegroundNotificationInfo(
            title: "Family Safety",
            content: "Waiting for pairing",
          );
          developer.log('⚠️ Device not paired', name: _tag);
        }

        developer.log('✅ Service initialization complete', name: _tag);
      } catch (e, stack) {
        developer.log(
          '❌ FAILED TO START SERVICE',
          name: _tag,
          error: e,
          stackTrace: stack,
          level: 1000,
        );

        // Try to set a basic notification anyway
        try {
          await service.setForegroundNotificationInfo(
            title: "Family Safety",
            content: "Service running with errors",
          );
        } catch (notifError) {
          developer.log(
            'Failed to set error notification',
            name: _tag,
            error: notifError,
          );
        }
      }
    }

    developer.log('========================================', name: _tag);

    // ✅ Heartbeat timer with status update
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (service is AndroidServiceInstance) {
        try {
          if (await service.isForegroundService()) {
            final now = DateTime.now();

            // Send heartbeat to server
            try {
              final deviceId = await LocalStorageService.getDeviceId();
              if (deviceId != null) {
                await _platform.invokeMethod('sendHeartbeat');
                developer.log('💓 Heartbeat sent', name: _tag);
              }
            } catch (e) {
              developer.log('Heartbeat failed', name: _tag, error: e);
            }

            // Update notification
            await service.setForegroundNotificationInfo(
              title: "Family Safety Active",
              content:
                  "Last check: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
            );
          } else {
            developer.log('Service not foreground, stopping timer', name: _tag);
            timer.cancel();
          }
        } catch (e) {
          developer.log('Timer error', name: _tag, error: e);
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
    developer.log('========================================', name: _tag);
    developer.log('▶️ STARTING BACKGROUND SERVICES', name: _tag);

    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();

      if (isRunning) {
        developer.log('⚠️ Service already running', name: _tag);
        developer.log('========================================', name: _tag);
        return;
      }

      developer.log('Starting service...', name: _tag);
      await service.startService();

      // Wait and verify
      await Future.delayed(const Duration(milliseconds: 1000));
      final nowRunning = await service.isRunning();

      if (nowRunning) {
        developer.log('✅ Service started successfully', name: _tag);
      } else {
        developer.log('⚠️ Service may not have started', name: _tag);
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ FAILED TO START SERVICE',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }

    developer.log('========================================', name: _tag);
  }

  static Future<void> stopBackgroundServices() async {
    developer.log('========================================', name: _tag);
    developer.log('⏹️ STOPPING SERVICES', name: _tag);

    // Cancel WorkManager
    try {
      await _platform.invokeMethod('stopPeriodicLocation');
      developer.log('✅ WorkManager stopped', name: _tag);
    } catch (e) {
      developer.log('Failed to stop location worker', name: _tag, error: e);
    }

    // Stop service
    final service = FlutterBackgroundService();
    service.invoke("stopService");

    developer.log('✅ Stop signal sent', name: _tag);
    developer.log('========================================', name: _tag);
  }

  static Future<bool> isServiceRunning() async {
    try {
      final service = FlutterBackgroundService();
      final running = await service.isRunning();
      developer.log('Service running: $running', name: _tag);
      return running;
    } catch (e) {
      developer.log('Error checking service status', name: _tag, error: e);
      return false;
    }
  }
}
