// controllers/permission_controller.dart - COMPLETE FIX
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:developer' as developer;

class PermissionController extends GetxController with WidgetsBindingObserver {
  static const String _tag = 'PermissionController';

  final RxBool locationGranted = false.obs;
  final RxBool cameraGranted = false.obs;
  final RxBool notificationGranted = false.obs;
  final RxBool storageGranted = false.obs;
  final RxBool batteryOptimizationDisabled = false.obs;
  final RxBool accessibilityGranted = false.obs;

  final RxBool isCheckingPermissions = false.obs;
  final RxInt currentPermissionIndex = 0.obs;
  final RxBool isWaitingForSettings = false.obs;

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

    // Add lifecycle observer untuk detect app resume
    WidgetsBinding.instance.addObserver(this);

    checkAllPermissions();
  }

  @override
  void onClose() {
    developer.log('PermissionController disposed', name: _tag);
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// CRITICAL: Detect when user returns from Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    developer.log('App lifecycle changed: $state', name: _tag);

    if (state == AppLifecycleState.resumed && isWaitingForSettings.value) {
      developer.log(
        'App resumed from Settings, re-checking permissions',
        name: _tag,
      );

      // User kembali dari Settings, check ulang permissions
      isWaitingForSettings.value = false;

      Future.delayed(const Duration(milliseconds: 500), () {
        checkAllPermissions();
      });
    }
  }

  Future<void> checkAllPermissions() async {
    developer.log('========================================', name: _tag);
    developer.log('CHECKING ALL PERMISSIONS', name: _tag);

    isCheckingPermissions.value = true;

    try {
      locationGranted.value = await Permission.locationAlways.isGranted;
      developer.log('Location: ${locationGranted.value}', name: _tag);

      cameraGranted.value = await Permission.camera.isGranted;
      developer.log('Camera: ${cameraGranted.value}', name: _tag);

      storageGranted.value =
          await Permission.storage.isGranted ||
          await Permission.photos.isGranted;
      developer.log('Storage: ${storageGranted.value}', name: _tag);

      if (Platform.isAndroid) {
        notificationGranted.value =
            await NotificationListenerService.isPermissionGranted();
        developer.log('Notification: ${notificationGranted.value}', name: _tag);

        batteryOptimizationDisabled.value =
            await Permission.ignoreBatteryOptimizations.isGranted;
        developer.log(
          'Battery Optimization: ${batteryOptimizationDisabled.value}',
          name: _tag,
        );
      } else {
        notificationGranted.value = true;
        batteryOptimizationDisabled.value = true;
        accessibilityGranted.value = true;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error checking permissions',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    } finally {
      isCheckingPermissions.value = false;
    }

    developer.log('========================================', name: _tag);

    // Update UI
    update(['permission_list', 'progress']);
  }

  Future<bool> requestLocationPermission() async {
    developer.log('Requesting location permission...', name: _tag);
    currentPermissionIndex.value = 0;
    update(['permission_list', 'progress']);

    PermissionStatus status = await Permission.locationAlways.request();
    developer.log('Location permission result: $status', name: _tag);

    if (status.isPermanentlyDenied) {
      developer.log(
        'Location permanently denied, opening settings',
        name: _tag,
      );

      Get.snackbar(
        'Permission Required',
        'Please enable location permission from settings',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      isWaitingForSettings.value = true;
      await openAppSettings();
      return false;
    }

    locationGranted.value = status.isGranted;
    update(['permission_list']);

    return status.isGranted;
  }

  Future<bool> requestCameraPermission() async {
    developer.log('Requesting camera permission...', name: _tag);
    currentPermissionIndex.value = 1;
    update(['permission_list', 'progress']);

    PermissionStatus status = await Permission.camera.request();
    developer.log('Camera permission result: $status', name: _tag);

    if (status.isPermanentlyDenied) {
      developer.log('Camera permanently denied, opening settings', name: _tag);

      Get.snackbar(
        'Permission Required',
        'Please enable camera permission from settings',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      isWaitingForSettings.value = true;
      await openAppSettings();
      return false;
    }

    cameraGranted.value = status.isGranted;
    update(['permission_list']);

    return status.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    developer.log('Requesting notification permission...', name: _tag);
    currentPermissionIndex.value = 2;
    update(['permission_list', 'progress']);

    if (Platform.isAndroid) {
      // Check current status first
      bool alreadyGranted =
          await NotificationListenerService.isPermissionGranted();
      developer.log(
        'Notification already granted: $alreadyGranted',
        name: _tag,
      );

      if (alreadyGranted) {
        notificationGranted.value = true;
        update(['permission_list']);
        return true;
      }

      // Show explanation dialog
      await Get.dialog(
        AlertDialog(
          title: const Text('Notification Access'),
          content: const Text(
            'This app needs to access notifications to mirror them to your parent\'s device.\n\n'
            'Steps:\n'
            '1. Tap "Open Settings"\n'
            '2. Find "couple_guard_child" or "Family Safety"\n'
            '3. Toggle it ON\n'
            '4. Return to app',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      // Open settings
      developer.log('Opening notification listener settings', name: _tag);
      isWaitingForSettings.value = true;

      bool? granted = await NotificationListenerService.requestPermission();

      // Wait a bit for settings to close
      await Future.delayed(const Duration(milliseconds: 1000));

      // Check again
      granted = await NotificationListenerService.isPermissionGranted();
      developer.log(
        'Notification permission after settings: $granted',
        name: _tag,
      );

      notificationGranted.value = granted ?? false;
      update(['permission_list']);

      return notificationGranted.value;
    }

    return true;
  }

  Future<bool> requestStoragePermission() async {
    developer.log('Requesting storage permission...', name: _tag);
    currentPermissionIndex.value = 3;
    update(['permission_list', 'progress']);

    PermissionStatus status = await Permission.storage.request();

    // For Android 13+, also request photos
    if (Platform.isAndroid) {
      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted) {
        status = photosStatus;
      }
    }

    developer.log('Storage permission result: $status', name: _tag);

    if (status.isPermanentlyDenied) {
      developer.log('Storage permanently denied, opening settings', name: _tag);

      Get.snackbar(
        'Permission Required',
        'Please enable storage permission from settings',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      isWaitingForSettings.value = true;
      await openAppSettings();
      return false;
    }

    storageGranted.value = status.isGranted;
    update(['permission_list']);

    return status.isGranted;
  }

  Future<bool> requestBatteryOptimization() async {
    developer.log('Requesting battery optimization disable...', name: _tag);
    currentPermissionIndex.value = 4;
    update(['permission_list', 'progress']);

    if (Platform.isAndroid) {
      // Show explanation first
      await Get.dialog(
        AlertDialog(
          title: const Text('Battery Optimization'),
          content: const Text(
            'To keep the app running in the background, you need to disable battery optimization.\n\n'
            'Tap "Open Settings" and select "Don\'t optimize" or "Allow".',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      isWaitingForSettings.value = true;
      PermissionStatus status = await Permission.ignoreBatteryOptimizations
          .request();
      developer.log('Battery optimization result: $status', name: _tag);

      batteryOptimizationDisabled.value = status.isGranted;
      update(['permission_list']);

      return status.isGranted;
    }

    return true;
  }

  Future<bool> requestAllPermissions() async {
    developer.log('========================================', name: _tag);
    developer.log('REQUESTING ALL PERMISSIONS', name: _tag);

    bool allGranted = true;

    // 1. Location
    if (!locationGranted.value) {
      if (!await requestLocationPermission()) allGranted = false;
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // 2. Camera
    if (!cameraGranted.value) {
      if (!await requestCameraPermission()) allGranted = false;
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // 3. Notification
    if (!notificationGranted.value) {
      if (!await requestNotificationPermission()) allGranted = false;
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // 4. Storage
    if (!storageGranted.value) {
      if (!await requestStoragePermission()) allGranted = false;
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // 5. Battery Optimization
    if (!batteryOptimizationDisabled.value) {
      if (!await requestBatteryOptimization()) allGranted = false;
      await Future.delayed(const Duration(milliseconds: 800));
    }

    developer.log('All permissions granted: $allGranted', name: _tag);
    developer.log('========================================', name: _tag);

    return allGranted;
  }

  bool areAllPermissionsGranted() {
    final allGranted = Platform.isAndroid
        ? locationGranted.value &&
              cameraGranted.value &&
              notificationGranted.value &&
              storageGranted.value &&
              batteryOptimizationDisabled.value
        : locationGranted.value && cameraGranted.value && storageGranted.value;

    developer.log('All permissions granted check: $allGranted', name: _tag);
    developer.log('  Location: ${locationGranted.value}', name: _tag);
    developer.log('  Camera: ${cameraGranted.value}', name: _tag);
    developer.log('  Notification: ${notificationGranted.value}', name: _tag);
    developer.log('  Storage: ${storageGranted.value}', name: _tag);
    developer.log(
      '  Battery: ${batteryOptimizationDisabled.value}',
      name: _tag,
    );

    return allGranted;
  }
}
