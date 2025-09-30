// controllers/dashboard_controller.dart
import 'package:get/get.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/local/local_storage_service.dart';
import '../services/api/device_service.dart';
import '../services/background/background_service_manager.dart';

class DashboardController extends GetxController {
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

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
    startMonitoring();
  }

  Future<void> loadDashboardData() async {
    // Load saved data
    familyCode.value = await LocalStorageService.getFamilyCode() ?? '';
    deviceId.value = await LocalStorageService.getDeviceId() ?? '';

    // Check battery
    batteryLevel.value = await _battery.batteryLevel;

    // Monitor battery changes
    _battery.onBatteryStateChanged.listen((BatteryState state) async {
      batteryLevel.value = await _battery.batteryLevel;
    });

    // Check connectivity
    checkConnectivity();

    // Monitor connectivity changes
    Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) {
            updateConnectionStatus(result);
          }
          as void Function(List<ConnectivityResult> event)?,
    );
  }

  Future<void> checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    updateConnectionStatus(connectivityResult as ConnectivityResult);
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

  void startMonitoring() {
    // Update monitoring status
    locationTracking.value = true;
    notificationMirroring.value = true;
    screenMonitoring.value = false; // Will be true when parent initiates

    // Ensure background services are running
    BackgroundServiceManager.startBackgroundServices();
  }

  void minimizeApp() {
    // This will minimize the app (Android only)
    // iOS doesn't support programmatic minimize
    if (GetPlatform.isAndroid) {
      // Native channel to minimize
      // Implementation in MainActivity.kt
    }
  }
}
