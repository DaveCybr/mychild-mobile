// controllers/permission_controller.dart
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'dart:io';

class PermissionController extends GetxController {
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
    checkAllPermissions();
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
      // accessibilityGranted.value =
      //     await Permission.accessibilityFeatures.isGranted;
    } else {
      // iOS specific checks
      notificationGranted.value = true; // iOS handles differently
      batteryOptimizationDisabled.value = true;
      accessibilityGranted.value = true;
    }

    isCheckingPermissions.value = false;
  }

  Future<bool> requestLocationPermission() async {
    currentPermissionIndex.value = 0;

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
    return status.isGranted;
  }

  Future<bool> requestCameraPermission() async {
    currentPermissionIndex.value = 1;

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
    return status.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    currentPermissionIndex.value = 2;

    if (Platform.isAndroid) {
      bool? granted = await NotificationListenerService.requestPermission();
      notificationGranted.value = granted ?? false;
      return notificationGranted.value;
    }

    return true;
  }

  Future<bool> requestStoragePermission() async {
    currentPermissionIndex.value = 3;

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
    return status.isGranted;
  }

  Future<bool> requestBatteryOptimization() async {
    currentPermissionIndex.value = 4;

    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.ignoreBatteryOptimizations
          .request();
      batteryOptimizationDisabled.value = status.isGranted;
      return status.isGranted;
    }

    return true;
  }

  // Future<bool> requestAccessibilityPermission() async {
  //   currentPermissionIndex.value = 5;

  //   if (Platform.isAndroid) {
  //     PermissionStatus status = await Permission.accessibilityFeatures
  //         .request();
  //     accessibilityGranted.value = status.isGranted;
  //     return status.isGranted;
  //   }

  //   return true;
  // }

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

    // if (!await requestAccessibilityPermission()) allGranted = false;

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
