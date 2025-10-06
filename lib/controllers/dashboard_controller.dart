// controllers/dashboard_controller.dart
import 'package:get/get.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/local/local_storage_service.dart';
import '../services/api/device_service.dart';
import '../services/background/background_service_manager.dart';
import 'dart:developer' as developer;

class DashboardController extends GetxController {
  static const String _tag = 'DashboardController';

  final DeviceService _deviceService = Get.find<DeviceService>();
  final Battery _battery = Battery();

  final RxString familyCode = ''.obs;
  final RxString deviceId = ''.obs;
  final RxBool isConnected = false.obs;
  final RxInt batteryLevel = 0.obs;
  final RxString connectionStatus = 'Checking...'.obs;

  // Monitoring status
  final RxBool locationTracking = false.obs;
  final RxBool notificationMirroring = false.obs;
  final RxBool screenMonitoring = false.obs;
  final RxBool backgroundServiceRunning = false.obs;

  @override
  void onInit() {
    super.onInit();
    developer.log('DashboardController initialized', name: _tag);
    loadDashboardData();
    startMonitoring();
  }

  Future<void> loadDashboardData() async {
    try {
      // Load saved data
      familyCode.value = await LocalStorageService.getFamilyCode() ?? '';
      deviceId.value = await LocalStorageService.getDeviceId() ?? '';

      developer.log(
        'Loaded - FamilyCode: ${familyCode.value}, DeviceId: ${deviceId.value}',
        name: _tag,
      );

      // Check battery
      batteryLevel.value = await _battery.batteryLevel;

      // Monitor battery changes
      _battery.onBatteryStateChanged.listen((BatteryState state) async {
        batteryLevel.value = await _battery.batteryLevel;
      });

      // Check connectivity
      checkConnectivity();

      // Monitor connectivity changes
      Connectivity().onConnectivityChanged.listen((
        List<ConnectivityResult> results,
      ) {
        if (results.isNotEmpty) {
          updateConnectionStatus(results.first);
        }
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error loading dashboard data',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  Future<void> checkConnectivity() async {
    try {
      var connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.isNotEmpty) {
        updateConnectionStatus(connectivityResults.first);
      }
    } catch (e) {
      developer.log(
        'Error checking connectivity',
        name: _tag,
        error: e,
        level: 900,
      );
      isConnected.value = false;
      connectionStatus.value = 'Unknown';
    }
  }

  void updateConnectionStatus(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.mobile:
        isConnected.value = true;
        connectionStatus.value = 'Connected (Mobile)';
        break;
      case ConnectivityResult.wifi:
        isConnected.value = true;
        connectionStatus.value = 'Connected (WiFi)';
        break;
      case ConnectivityResult.none:
        isConnected.value = false;
        connectionStatus.value = 'No Connection';
        break;
      default:
        isConnected.value = false;
        connectionStatus.value = 'Unknown';
    }

    // Update device status
    _deviceService.updateDeviceStatus(isConnected.value);
  }

  void startMonitoring() async {
    try {
      developer.log('Starting monitoring services', name: _tag);

      // Update monitoring status immediately for UI
      locationTracking.value = true;
      notificationMirroring.value = true;
      screenMonitoring.value = false;

      // Check if service is already running
      bool isRunning = await BackgroundServiceManager.isServiceRunning();

      if (isRunning) {
        developer.log('Background service already running', name: _tag);
        backgroundServiceRunning.value = true;
        return;
      }

      // Start background service with proper delay
      Future.delayed(const Duration(milliseconds: 500), () async {
        try {
          BackgroundServiceManager.startBackgroundServices();

          // Verify service started
          await Future.delayed(const Duration(milliseconds: 1000));
          bool started = await BackgroundServiceManager.isServiceRunning();

          backgroundServiceRunning.value = started;

          if (started) {
            developer.log(
              '✓ Background service started successfully',
              name: _tag,
            );
          } else {
            developer.log(
              '⚠ Background service failed to start',
              name: _tag,
              level: 900,
            );
          }
        } catch (e) {
          developer.log(
            'Error starting background service',
            name: _tag,
            error: e,
            level: 1000,
          );
          backgroundServiceRunning.value = false;
        }
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error in startMonitoring',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  void minimizeApp() {
    // This will minimize the app (Android only)
    if (GetPlatform.isAndroid) {
      developer.log('Minimizing app', name: _tag);
      // Native channel to minimize - handled by SystemNavigator.pop() in UI
    }
  }

  @override
  void onClose() {
    developer.log('DashboardController disposed', name: _tag);
    super.onClose();
  }
}
