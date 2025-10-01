// controllers/permission_controller.dart
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'dart:io';
import 'dart:developer' as developer;

class PermissionController extends GetxController {
  static const String _tag = 'PermissionController';

  final RxBool locationGranted = false.obs;
  final RxBool cameraGranted = false.obs;
  final RxBool notificationGranted = false.obs;
  final RxBool storageGranted = false.obs;
  final RxBool batteryOptimizationDisabled = false.obs;
  final RxBool accessibilityGranted = false.obs;

  final RxBool isCheckingPermissions = false.obs;
  final RxInt currentPermissionIndex = 0.obs;

  final List<String> permissionTitles = [
    'Location Access',
    'Camera Access',
    'Notification Access',
    'Storage Access',
    'Battery Optimization',
    'Accessibility Service',
  ];

  final List<String> permissionDescriptions = [
    'Required to track device location for safety',
    'Needed for emergency photo capture',
    'Required to mirror notifications',
    'Needed to save monitoring data',
    'Disable to keep app running in background',
    'Required for screen monitoring features',
  ];

  @override
  void onInit() {
    super.onInit();
    developer.log('PermissionController initialized', name: _tag);
    checkAllPermissions();
  }

  @override
  void onClose() {
    developer.log('PermissionController disposed', name: _tag);
    super.onClose();
  }

  Future<void> checkAllPermissions() async {
    isCheckingPermissions.value = true;

    locationGranted.value = await Permission.locationAlways.isGranted;
    cameraGranted.value = await Permission.camera.isGranted;
    storageGranted.value = await Permission.storage.isGranted;

    if (Platform.isAndroid) {
      notificationGranted.value =
          await NotificationListenerService.isPermissionGranted();
      batteryOptimizationDisabled.value =
          await Permission.ignoreBatteryOptimizations.isGranted;
    } else {
      notificationGranted.value = true;
      batteryOptimizationDisabled.value = true;
      accessibilityGranted.value = true;
    }

    isCheckingPermissions.value = false;

    // Update UI
    update(['permission_list', 'progress']);
  }

  Future<bool> requestLocationPermission() async {
    currentPermissionIndex.value = 0;
    update(['permission_list', 'progress']);

    PermissionStatus status = await Permission.locationAlways.request();

    if (status.isPermanentlyDenied) {
      Get.snackbar(
        'Permission Required',
        'Please enable location permission from settings',
        snackPosition: SnackPosition.TOP,
      );
      await openAppSettings();
      return false;
    }

    locationGranted.value = status.isGranted;
    update(['permission_list']);
    return status.isGranted;
  }

  Future<bool> requestCameraPermission() async {
    currentPermissionIndex.value = 1;
    update(['permission_list', 'progress']);

    PermissionStatus status = await Permission.camera.request();

    if (status.isPermanentlyDenied) {
      Get.snackbar(
        'Permission Required',
        'Please enable camera permission from settings',
        snackPosition: SnackPosition.TOP,
      );
      await openAppSettings();
      return false;
    }

    cameraGranted.value = status.isGranted;
    update(['permission_list']);
    return status.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    currentPermissionIndex.value = 2;
    update(['permission_list', 'progress']);

    if (Platform.isAndroid) {
      bool? granted = await NotificationListenerService.requestPermission();
      notificationGranted.value = granted ?? false;
      update(['permission_list']);
      return notificationGranted.value;
    }

    return true;
  }

  Future<bool> requestStoragePermission() async {
    currentPermissionIndex.value = 3;
    update(['permission_list', 'progress']);

    PermissionStatus status = await Permission.storage.request();

    if (status.isPermanentlyDenied) {
      Get.snackbar(
        'Permission Required',
        'Please enable storage permission from settings',
        snackPosition: SnackPosition.TOP,
      );
      await openAppSettings();
      return false;
    }

    storageGranted.value = status.isGranted;
    update(['permission_list']);
    return status.isGranted;
  }

  Future<bool> requestBatteryOptimization() async {
    currentPermissionIndex.value = 4;
    update(['permission_list', 'progress']);

    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.ignoreBatteryOptimizations
          .request();
      batteryOptimizationDisabled.value = status.isGranted;
      update(['permission_list']);
      return status.isGranted;
    }

    return true;
  }

  Future<bool> requestAllPermissions() async {
    bool allGranted = true;

    if (!await requestLocationPermission()) allGranted = false;
    await Future.delayed(const Duration(milliseconds: 500));

    if (!await requestCameraPermission()) allGranted = false;
    await Future.delayed(const Duration(milliseconds: 500));

    if (!await requestNotificationPermission()) allGranted = false;
    await Future.delayed(const Duration(milliseconds: 500));

    if (!await requestStoragePermission()) allGranted = false;
    await Future.delayed(const Duration(milliseconds: 500));

    if (!await requestBatteryOptimization()) allGranted = false;
    await Future.delayed(const Duration(milliseconds: 500));

    return allGranted;
  }

  bool areAllPermissionsGranted() {
    if (Platform.isAndroid) {
      return locationGranted.value &&
          cameraGranted.value &&
          notificationGranted.value &&
          storageGranted.value &&
          batteryOptimizationDisabled.value &&
          accessibilityGranted.value;
    } else {
      return locationGranted.value &&
          cameraGranted.value &&
          storageGranted.value;
    }
  }
}
