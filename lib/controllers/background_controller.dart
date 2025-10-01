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

  @override
  void onInit() {
    super.onInit();
    developer.log('BackgroundController initialized', name: _tag);
    // JANGAN auto-start services di sini
    // Biarkan dashboard yang trigger manual setelah semua ready
  }

  Future<void> initializeAllServices() async {
    try {
      developer.log('Starting to initialize all services', name: _tag);

      // Initialize camera service
      await CameraService.initialize();
      developer.log('Camera service initialized', name: _tag);

      // Start background service AFTER everything is ready
      BackgroundServiceManager.startBackgroundServices();
      developer.log('Background service started', name: _tag);

      // Give time for background service to start
      await Future.delayed(Duration(milliseconds: 1000));

      // Start individual monitoring services
      LocationService.startTracking();
      developer.log('Location tracking started', name: _tag);

      NotificationService.startListening();
      developer.log('Notification listening started', name: _tag);

      ScreenMonitorService.startMonitoring();
      developer.log('Screen monitoring started', name: _tag);

      servicesRunning.value = true;
      developer.log('All services running successfully', name: _tag);
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing services',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  void stopAllServices() {
    developer.log('Stopping all services', name: _tag);

    LocationService.stopTracking();
    NotificationService.stopListening();
    ScreenMonitorService.stopMonitoring();
    BackgroundServiceManager.stopBackgroundServices();

    servicesRunning.value = false;

    developer.log('All services stopped', name: _tag);
  }

  void handleParentCommand(Map<String, dynamic> command) {
    developer.log('Received parent command: ${command['type']}', name: _tag);

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
        if (!servicesRunning.value) {
          initializeAllServices();
        }
        break;
      case 'STOP_MONITORING':
        stopAllServices();
        break;
    }
  }
}
