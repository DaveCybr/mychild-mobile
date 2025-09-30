// controllers/background_controller.dart
import 'package:get/get.dart';
import '../services/background/background_service_manager.dart';
import '../services/background/location_service.dart';
import '../services/background/notification_service.dart';
import '../services/background/screen_monitor_service.dart';
import '../services/background/camera_service.dart';

class BackgroundController extends GetxController {
  static BackgroundController get to => Get.find();

  final RxBool servicesRunning = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Delay initialization untuk memastikan Flutter sudah ready
    Future.delayed(Duration(milliseconds: 500), () {
      initializeAllServices();
    });
  }

  Future<void> initializeAllServices() async {
    try {
      // Initialize camera service
      await CameraService.initialize();

      // Start background service AFTER everything is ready
      BackgroundServiceManager.startBackgroundServices();

      // Give time for background service to start
      await Future.delayed(Duration(milliseconds: 1000));

      // Start individual monitoring services
      LocationService.startTracking();
      NotificationService.startListening();
      ScreenMonitorService.startMonitoring();

      servicesRunning.value = true;
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  void stopAllServices() {
    LocationService.stopTracking();
    NotificationService.stopListening();
    ScreenMonitorService.stopMonitoring();
    BackgroundServiceManager.stopBackgroundServices();

    servicesRunning.value = false;
  }

  void handleParentCommand(Map<String, dynamic> command) {
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
