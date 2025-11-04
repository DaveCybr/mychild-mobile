// lib/controllers/background_controller.dart - FIXED
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // ✅ ADD THIS
import 'dart:developer' as developer;
import '../services/background/background_service_manager.dart';
import '../services/background/location_service.dart';
import '../services/background/notification_service.dart';
import '../services/background/screen_monitor_service.dart';
import '../services/background/camera_service.dart';

class BackgroundController extends GetxController {
  static const String _tag = 'BackgroundController';
  static BackgroundController get to => Get.find();

  // ✅ ADD: Define MethodChannel
  static const _notificationPlatform = MethodChannel(
    'notification_listener_channel',
  );
  static const _locationPlatform = MethodChannel('location_worker_channel');

  final RxBool servicesRunning = false.obs;
  final RxBool locationActive = false.obs;
  final RxBool notificationActive = false.obs;
  final RxBool screenMonitorActive = false.obs;

  @override
  void onInit() {
    super.onInit();
    developer.log('BackgroundController initialized', name: _tag);
  }

  /// Initialize all background services
  Future<void> initializeAllServices() async {
    if (servicesRunning.value) {
      developer.log(
        'Services already running, skipping initialization',
        name: _tag,
      );
      return;
    }

    developer.log('========================================', name: _tag);
    developer.log('INITIALIZING ALL SERVICES', name: _tag);
    developer.log('========================================', name: _tag);

    try {
      // ✅ FIX: Check permissions properly
      developer.log('Checking permissions...', name: _tag);

      // Check location permission
      final fgLocation = await Permission.location.isGranted;
      final bgLocation = await Permission.locationAlways.isGranted;
      final hasLocationPermission = fgLocation || bgLocation;

      developer.log(
        'Location (FG): $fgLocation, (BG): $bgLocation',
        name: _tag,
      );

      if (!hasLocationPermission) {
        developer.log('❌ Location permission NOT granted!', name: _tag);

        Get.snackbar(
          'Permission Required',
          'Location permission is required to start monitoring',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      developer.log('✅ Location permission granted', name: _tag);

      // Check camera permission
      final cameraGranted = await Permission.camera.isGranted;
      developer.log('Camera: $cameraGranted', name: _tag);

      if (!cameraGranted) {
        developer.log(
          '⚠️ Camera permission not granted (photo capture will fail)',
          name: _tag,
        );
      }

      // Check battery optimization
      developer.log('Checking battery optimization...', name: _tag);
      try {
        final isIgnoring =
            await _notificationPlatform.invokeMethod<bool>(
              'checkBatteryOptimization',
            ) ??
            false;

        developer.log('Battery optimization ignored: $isIgnoring', name: _tag);

        if (!isIgnoring) {
          developer.log('⚠️ Battery optimization NOT disabled', name: _tag);

          // Request battery optimization exemption
          try {
            await _notificationPlatform.invokeMethod(
              'requestBatteryOptimization',
            );
            developer.log('✅ Battery optimization dialog shown', name: _tag);
          } catch (e) {
            developer.log(
              'Failed to show battery dialog',
              name: _tag,
              error: e,
            );
          }
        }
      } catch (e) {
        developer.log(
          'Failed to check battery optimization',
          name: _tag,
          error: e,
        );
      }

      // STEP 1: Initialize camera service
      developer.log('Initializing camera service...', name: _tag);
      await CameraService.initialize();
      developer.log('✅ Camera service initialized', name: _tag);

      // STEP 2: Start background service
      developer.log('Starting background service manager...', name: _tag);
      await BackgroundServiceManager.startBackgroundServices();
      developer.log('✅ Background service start command sent', name: _tag);

      // STEP 3: Wait for service to initialize
      await Future.delayed(const Duration(milliseconds: 2000));

      // STEP 4: Explicitly start WorkManager dari native
      developer.log('Starting WorkManager from native...', name: _tag);
      try {
        await _locationPlatform.invokeMethod('startPeriodicLocation');
        developer.log('✅ WorkManager start command sent', name: _tag);

        // Verify it was scheduled
        await Future.delayed(const Duration(milliseconds: 1000));

        final isScheduled =
            await _locationPlatform.invokeMethod<bool>(
              'isLocationWorkScheduled',
            ) ??
            false;

        developer.log('WorkManager scheduled: $isScheduled', name: _tag);

        if (!isScheduled) {
          developer.log(
            '⚠️ WorkManager NOT scheduled! Retrying...',
            name: _tag,
          );

          // Retry once
          await _locationPlatform.invokeMethod('startPeriodicLocation');
          await Future.delayed(const Duration(milliseconds: 1000));

          final retryCheck =
              await _locationPlatform.invokeMethod<bool>(
                'isLocationWorkScheduled',
              ) ??
              false;

          developer.log('Retry result: $retryCheck', name: _tag);

          if (!retryCheck) {
            throw Exception('WorkManager failed to schedule after retry');
          }
        }

        // Get work status
        try {
          final status = await _locationPlatform.invokeMethod<String>(
            'getLocationWorkStatus',
          );
          developer.log('WorkManager status: $status', name: _tag);
        } catch (e) {
          developer.log('Could not get work status', name: _tag, error: e);
        }
      } catch (e) {
        developer.log(
          'Failed to start WorkManager',
          name: _tag,
          error: e,
          level: 1000,
        );
        throw Exception('WorkManager initialization failed: $e');
      }

      // STEP 5: Verify background service is running
      final isRunning = await BackgroundServiceManager.isServiceRunning();
      developer.log('Background service running: $isRunning', name: _tag);

      if (isRunning) {
        servicesRunning.value = true;
        locationActive.value = true;
        notificationActive.value = true;
        screenMonitorActive.value = false;

        developer.log('========================================', name: _tag);
        developer.log('✅ ALL SERVICES RUNNING SUCCESSFULLY', name: _tag);
        developer.log(
          'Location tracking: ACTIVE (30 min interval)',
          name: _tag,
        );
        developer.log('Notification mirroring: ACTIVE', name: _tag);
        developer.log('========================================', name: _tag);
      } else {
        throw Exception('Background service failed to start');
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ ERROR INITIALIZING SERVICES',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );

      servicesRunning.value = false;
      locationActive.value = false;
      notificationActive.value = false;
      screenMonitorActive.value = false;

      // Show error to user
      Get.snackbar(
        'Error',
        'Failed to start background services: $e',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );

      rethrow; // Propagate error
    }
  }

  /// Stop all background services
  Future<void> stopAllServices() async {
    developer.log('========================================', name: _tag);
    developer.log('STOPPING ALL SERVICES', name: _tag);

    try {
      // Stop location tracking
      LocationService.stopTracking();
      developer.log('✅ Location tracking stopped', name: _tag);

      // Stop WorkManager
      try {
        await _locationPlatform.invokeMethod('stopPeriodicLocation');
        developer.log('✅ WorkManager cancelled', name: _tag);
      } catch (e) {
        developer.log('Failed to stop WorkManager', name: _tag, error: e);
      }

      // Stop notification listening
      NotificationService.stopListening();
      developer.log('✅ Notification listening stopped', name: _tag);

      // Stop screen monitoring
      ScreenMonitorService.stopMonitoring();
      developer.log('✅ Screen monitoring stopped', name: _tag);

      // Stop background service
      await BackgroundServiceManager.stopBackgroundServices();
      developer.log('✅ Background service stopped', name: _tag);

      servicesRunning.value = false;
      locationActive.value = false;
      notificationActive.value = false;
      screenMonitorActive.value = false;

      developer.log('========================================', name: _tag);
      developer.log('✅ ALL SERVICES STOPPED', name: _tag);
      developer.log('========================================', name: _tag);

      // Show message
      Get.snackbar(
        'Monitoring Stopped',
        'All services have been stopped',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error stopping services',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  /// Check notification listener permission
  Future<bool> checkNotificationPermission() async {
    try {
      final hasPermission =
          await _notificationPlatform.invokeMethod<bool>(
            'checkNotificationPermission',
          ) ??
          false;

      developer.log('Notification permission: $hasPermission', name: _tag);
      notificationActive.value = hasPermission;

      return hasPermission;
    } catch (e) {
      developer.log(
        'Failed to check notification permission',
        name: _tag,
        error: e,
      );
      return false;
    }
  }

  /// Open notification listener settings
  Future<void> openNotificationSettings() async {
    try {
      await _notificationPlatform.invokeMethod('openNotificationSettings');
      developer.log('Opened notification settings', name: _tag);
    } catch (e) {
      developer.log(
        'Failed to open notification settings',
        name: _tag,
        error: e,
      );
    }
  }

  @override
  void onClose() {
    developer.log('BackgroundController disposed', name: _tag);
    super.onClose();
  }
}
