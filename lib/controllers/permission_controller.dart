// controllers/permission_controller.dart - LOCATION FIX
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

  final RxBool isCheckingPermissions = false.obs;
  final RxInt currentPermissionIndex = 0.obs;
  final RxBool isWaitingForSettings = false.obs;

  // ✅ UPDATE: Add screen capture to list
  final List<String> permissionTitles = [
    'Location Access',
    'Background Location',
    'Camera Access',
    'Notification Access',
    'Storage Access',
    'Battery Optimization',
  ];

  // ✅ UPDATE: Add description
  final List<String> permissionDescriptions = [
    'Required to track device location for safety',
    'Allows location tracking when app is closed',
    'Needed for emergency photo capture',
    'Required to mirror notifications',
    'Needed to save monitoring data',
    'Disable to keep app running in background',
  ];

  @override
  void onInit() {
    super.onInit();
    developer.log('PermissionController initialized', name: _tag);
    WidgetsBinding.instance.addObserver(this);
    checkAllPermissions();
  }

  @override
  void onClose() {
    developer.log('PermissionController disposed', name: _tag);
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    developer.log('App lifecycle changed: $state', name: _tag);

    if (state == AppLifecycleState.resumed && isWaitingForSettings.value) {
      developer.log(
        'App resumed from Settings, re-checking permissions',
        name: _tag,
      );
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
      // Check foreground location first
      final fgLocation = await Permission.location.isGranted;
      final bgLocation = await Permission.locationAlways.isGranted;

      // Location is granted if EITHER foreground OR background is granted
      locationGranted.value = fgLocation || bgLocation;
      developer.log(
        'Location (FG): $fgLocation, (BG): $bgLocation',
        name: _tag,
      );

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
    update(['permission_list', 'progress']);
  }

  Future<bool> requestLocationPermission() async {
    developer.log('========================================', name: _tag);
    developer.log('REQUESTING LOCATION PERMISSION (Step 1/2)', name: _tag);

    currentPermissionIndex.value = 0;
    update(['permission_list', 'progress']);

    developer.log('Step 1: Requesting FOREGROUND location...', name: _tag);

    PermissionStatus fgStatus = await Permission.location.request();
    developer.log('Foreground location result: $fgStatus', name: _tag);

    if (fgStatus.isPermanentlyDenied) {
      developer.log(
        'Location permanently denied, opening settings',
        name: _tag,
      );

      // ✅ WAJIB buka settings
      await Get.dialog(
        barrierDismissible: false, // ✅ User tidak bisa close
        AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Permission Required'),
            ],
          ),
          content: const Text(
            'Location permission is REQUIRED for this app to work.\n\n'
            'Please enable it in Settings.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      isWaitingForSettings.value = true;
      await openAppSettings();
      return false;
    }

    if (!fgStatus.isGranted) {
      developer.log('Foreground location DENIED by user', name: _tag);

      // ✅ Tanya lagi sampai granted
      await Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Location permission is required.\n\nPlease allow location access.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );

      locationGranted.value = false;
      update(['permission_list']);
      return false; // Will retry
    }

    developer.log('✅ Foreground location GRANTED', name: _tag);
    locationGranted.value = true;
    update(['permission_list']);

    developer.log('========================================', name: _tag);
    return true;
  }

  Future<bool> requestBackgroundLocationPermission() async {
    developer.log('========================================', name: _tag);
    developer.log('REQUESTING BACKGROUND LOCATION (Step 2/2)', name: _tag);

    currentPermissionIndex.value = 1;
    update(['permission_list', 'progress']);

    final fgGranted = await Permission.location.isGranted;
    if (!fgGranted) {
      developer.log(
        '❌ Cannot request background - foreground not granted',
        name: _tag,
      );
      return false;
    }

    // ✅ WAJIB - tidak ada tombol Cancel
    await Get.dialog(
      barrierDismissible: false,
      AlertDialog(
        title: const Text('Background Location Required'),
        content: const Text(
          'To keep tracking your location when the app is closed, '
          'you MUST select "Allow all the time" in the next screen.\n\n'
          'This is REQUIRED for family safety.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    developer.log(
      'Requesting BACKGROUND location (locationAlways)...',
      name: _tag,
    );

    PermissionStatus bgStatus = await Permission.locationAlways.request();
    developer.log('Background location result: $bgStatus', name: _tag);

    if (bgStatus.isPermanentlyDenied || !bgStatus.isGranted) {
      developer.log('Background location denied', name: _tag);

      // ✅ WAJIB buka settings
      await Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Permission Required'),
            ],
          ),
          content: const Text(
            'Background location is REQUIRED.\n\n'
            'Please select "Allow all the time" in Settings.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      isWaitingForSettings.value = true;
      await openAppSettings();
      return false;
    }

    developer.log('✅ Background location GRANTED', name: _tag);
    developer.log('========================================', name: _tag);
    update(['permission_list']);
    return true;
  }

  Future<bool> requestCameraPermission() async {
    developer.log('Requesting camera permission...', name: _tag);
    currentPermissionIndex.value = 2;
    update(['permission_list', 'progress']);

    PermissionStatus status = await Permission.camera.request();
    developer.log('Camera permission result: $status', name: _tag);

    if (status.isPermanentlyDenied || !status.isGranted) {
      // ✅ WAJIB buka settings
      await Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Permission Required'),
            ],
          ),
          content: const Text(
            'Camera permission is REQUIRED.\n\n'
            'Please enable it in Settings.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      isWaitingForSettings.value = true;
      await openAppSettings();
      cameraGranted.value = false;
      update(['permission_list']);
      return false;
    }

    cameraGranted.value = status.isGranted;
    update(['permission_list']);
    return status.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    developer.log('Requesting notification permission...', name: _tag);
    currentPermissionIndex.value = 3;
    update(['permission_list', 'progress']);

    if (Platform.isAndroid) {
      bool alreadyGranted =
          await NotificationListenerService.isPermissionGranted();

      if (alreadyGranted) {
        notificationGranted.value = true;
        update(['permission_list']);
        return true;
      }

      // ✅ WAJIB - tidak ada tombol Cancel
      await Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: const Text('Notification Access Required'),
          content: const Text(
            'This app REQUIRES notification access.\n\n'
            'Steps:\n'
            '1. Tap "Open Settings"\n'
            '2. Find "Family Safety"\n'
            '3. Toggle it ON\n'
            '4. Return to app',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      isWaitingForSettings.value = true;
      await NotificationListenerService.requestPermission();

      await Future.delayed(const Duration(milliseconds: 1000));

      bool? granted = await NotificationListenerService.isPermissionGranted();
      notificationGranted.value = granted ?? false;
      update(['permission_list']);

      return notificationGranted.value;
    }

    return true;
  }

  Future<bool> requestStoragePermission() async {
    developer.log('Requesting storage permission...', name: _tag);
    currentPermissionIndex.value = 4;
    update(['permission_list', 'progress']);

    PermissionStatus status = await Permission.storage.request();

    if (Platform.isAndroid) {
      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted) {
        status = photosStatus;
      }
    }

    if (status.isPermanentlyDenied || !status.isGranted) {
      // ✅ WAJIB buka settings
      await Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Permission Required'),
            ],
          ),
          content: const Text(
            'Storage permission is REQUIRED.\n\n'
            'Please enable it in Settings.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      isWaitingForSettings.value = true;
      await openAppSettings();
      storageGranted.value = false;
      update(['permission_list']);
      return false;
    }

    storageGranted.value = status.isGranted;
    update(['permission_list']);
    return status.isGranted;
  }

  Future<bool> requestBatteryOptimization() async {
    developer.log('Requesting battery optimization disable...', name: _tag);
    currentPermissionIndex.value = 5;
    update(['permission_list', 'progress']);

    if (Platform.isAndroid) {
      // ✅ WAJIB - tidak ada tombol Skip
      await Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: const Text('Battery Optimization Required'),
          content: const Text(
            'You MUST disable battery optimization to keep the app running.\n\n'
            'Tap "Open Settings" and select "Don\'t optimize".',
          ),
          actions: [
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

      batteryOptimizationDisabled.value = status.isGranted;
      update(['permission_list']);

      return status.isGranted;
    }

    return true;
  }

  // ✅ UPDATE: Include screen capture in request flow
  Future<bool> requestAllPermissions() async {
    developer.log('========================================', name: _tag);
    developer.log('REQUESTING ALL PERMISSIONS', name: _tag);

    bool allGranted = true;

    // 1. Foreground Location
    if (!locationGranted.value) {
      if (!await requestLocationPermission()) allGranted = false;
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    // 2. Background Location
    if (locationGranted.value) {
      await requestBackgroundLocationPermission();
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    // 3. Camera
    if (!cameraGranted.value) {
      if (!await requestCameraPermission()) allGranted = false;
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // 4. Notification
    if (!notificationGranted.value) {
      if (!await requestNotificationPermission()) allGranted = false;
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // 5. Storage
    if (!storageGranted.value) {
      if (!await requestStoragePermission()) allGranted = false;
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // 6. Battery Optimization
    if (!batteryOptimizationDisabled.value) {
      if (!await requestBatteryOptimization()) allGranted = false;
      await Future.delayed(const Duration(milliseconds: 800));
    }

    developer.log('All permissions process completed', name: _tag);
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
        : locationGranted.value &&
              cameraGranted.value &&
              storageGranted.value; // ✅ WAJIB

    return allGranted;
  }

  // ✅ HAPUS atau ubah areAllCriticalPermissionsGranted()
  bool areAllCriticalPermissionsGranted() {
    // Same as areAllPermissionsGranted() - semua wajib
    return areAllPermissionsGranted();
  }
}
