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
      developer.log('Services already initialized', name: _tag);
      return;
    }

    isInitializing.value = true;

    try {
      developer.log('🚀 Initializing services', name: _tag);

      // Check current status
      bool isRunning = await BackgroundServiceManager.isServiceRunning();

      if (isRunning) {
        developer.log('✓ Service already running', name: _tag);
        servicesRunning.value = true;
        isInitializing.value = false;
        return;
      }

      // Initialize camera (quick)
      try {
        await CameraService.initialize();
        developer.log('✓ Camera initialized', name: _tag);
      } catch (e) {
        developer.log('Camera init failed', name: _tag, error: e);
      }

      // ✅ Start service
      developer.log('Starting background service', name: _tag);
      BackgroundServiceManager.startBackgroundServices();

      // ✅ Wait reasonable time
      await Future.delayed(const Duration(milliseconds: 1500));

      // Verify
      isRunning = await BackgroundServiceManager.isServiceRunning();
      servicesRunning.value = isRunning;

      if (isRunning) {
        developer.log('✅ Services started successfully', name: _tag);
      } else {
        developer.log('❌ Service failed to start', name: _tag, level: 900);
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error initializing services',
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
