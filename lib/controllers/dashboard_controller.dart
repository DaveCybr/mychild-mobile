// controllers/dashboard_controller.dart
import 'package:get/get.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import '../services/local/local_storage_service.dart';
import '../services/api/device_service.dart';
import '../services/background/background_service_manager.dart';

class DashboardController extends GetxController {
  static const String _tag = 'DashboardController';
  static const MethodChannel _channel = MethodChannel(
    'notification_listener_channel',
  );

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
  final RxBool servicesRunning = false.obs;

  @override
  void onInit() {
    super.onInit();
    developer.log('Dashboard controller initialized', name: _tag);
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    developer.log('Loading dashboard data...', name: _tag);

    // Load saved data
    familyCode.value = await LocalStorageService.getFamilyCode() ?? '';
    deviceId.value = await LocalStorageService.getDeviceId() ?? '';

    developer.log('Family code: ${familyCode.value}', name: _tag);
    developer.log(
      'Device ID: ${deviceId.value.isNotEmpty ? deviceId.value.substring(0, 8) + "..." : "empty"}',
      name: _tag,
    );

    // Check battery
    batteryLevel.value = await _battery.batteryLevel;
    developer.log('Battery level: ${batteryLevel.value}%', name: _tag);

    // Monitor battery changes
    _battery.onBatteryStateChanged.listen((BatteryState state) async {
      batteryLevel.value = await _battery.batteryLevel;
      developer.log('Battery updated: ${batteryLevel.value}%', name: _tag);
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

    // Start monitoring with delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      startMonitoring();
      // if (mounted) {
      // }
    });
  }

  Future<void> checkConnectivity() async {
    try {
      var connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.isNotEmpty) {
        updateConnectionStatus(connectivityResults.first);
      }
    } catch (e) {
      developer.log('Error checking connectivity', name: _tag, error: e);
      isConnected.value = false;
      connectionStatus.value = 'Unknown';
    }
  }

  void updateConnectionStatus(ConnectivityResult result) {
    developer.log('Connectivity changed: $result', name: _tag);

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

    // Update device status on server
    _deviceService.updateDeviceStatus(isConnected.value);
  }

  Future<void> startMonitoring() async {
    developer.log('========================================', name: _tag);
    developer.log('STARTING MONITORING', name: _tag);

    try {
      // Check if service is already running
      final isRunning = await BackgroundServiceManager.isServiceRunning();
      developer.log('Background service running: $isRunning', name: _tag);

      if (!isRunning) {
        developer.log('Starting background service...', name: _tag);
        BackgroundServiceManager.startBackgroundServices();

        // Wait for service to start
        await Future.delayed(const Duration(seconds: 2));

        final nowRunning = await BackgroundServiceManager.isServiceRunning();
        developer.log('Service started: $nowRunning', name: _tag);
      }

      // Update UI status
      locationTracking.value = true;
      notificationMirroring.value = true;
      screenMonitoring.value = false; // Only active when parent requests
      servicesRunning.value = true;

      developer.log('✅ All monitoring services active', name: _tag);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error starting monitoring',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      servicesRunning.value = false;
    }

    developer.log('========================================', name: _tag);
  }

  Future<void> stopMonitoring() async {
    developer.log('Stopping all monitoring services', name: _tag);

    BackgroundServiceManager.stopBackgroundServices();

    locationTracking.value = false;
    notificationMirroring.value = false;
    screenMonitoring.value = false;
    servicesRunning.value = false;

    developer.log('✅ All monitoring services stopped', name: _tag);
  }

  void minimizeApp() {
    developer.log('Minimizing app', name: _tag);

    try {
      if (GetPlatform.isAndroid) {
        _channel.invokeMethod('minimizeApp');
        developer.log('Minimize command sent', name: _tag);
      }
    } catch (e) {
      developer.log('Error minimizing app', name: _tag, error: e);
      // Fallback
      SystemNavigator.pop();
    }
  }

  @override
  void onClose() {
    developer.log('Dashboard controller disposed', name: _tag);
    super.onClose();
  }
}
