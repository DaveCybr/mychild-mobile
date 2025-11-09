// controllers/permission_controller.dart - COMPLETE FIX
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:developer' as developer;

import '../services/background/screen_capture_service.dart';

class PermissionController extends GetxController with WidgetsBindingObserver {
  static const String _tag = 'PermissionController';

  final RxBool locationGranted = false.obs;
  final RxBool cameraGranted = false.obs;
  final RxBool notificationGranted = false.obs;
  final RxBool storageGranted = false.obs;
  final RxBool batteryOptimizationDisabled = false.obs;
  final RxBool screenCaptureGranted = false.obs;
  final RxBool accessibilityGranted = false.obs;

  final RxBool isCheckingPermissions = false.obs;
  final RxInt currentPermissionIndex = 0.obs;
  final RxBool isWaitingForSettings = false.obs;

  // ✅ FIX: Correct order - Location should be TWO items (FG + BG)
  final List<String> permissionTitles = [
    'Location Access', // 0
    'Camera Access', // 1
    'Notification Access', // 2
    'Storage Access', // 3
    'Battery Optimization', // 4
    'Screen Capture Permission', // 5
    'Accessibility Service', // 6
  ];

  final List<String> permissionDescriptions = [
    'Required to track device location (includes background)',
    'Needed for emergency photo capture',
    'Required to mirror notifications',
    'Needed to save monitoring data',
    'Disable to keep app running in background',
    'Required for MediaProjection screen capture',
    'Required for automatic screen capture via Accessibility',
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
      developer.log('App resumed from Settings, re-checking', name: _tag);
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
      // ✅ FIX: Check BOTH foreground AND background location
      final fgLocation = await Permission.location.isGranted;
      final bgLocation = await Permission.locationAlways.isGranted;

      // Location is fully granted only if BOTH are granted
      locationGranted.value = fgLocation && bgLocation;

      developer.log(
        'Location (FG): $fgLocation, (BG): $bgLocation',
        name: _tag,
      );
      developer.log(
        'Location (Combined): ${locationGranted.value}',
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
            await NotificationListenerService.isPermissionGranted() ?? false;
        developer.log('Notification: ${notificationGranted.value}', name: _tag);

        batteryOptimizationDisabled.value =
            await Permission.ignoreBatteryOptimizations.isGranted;
        developer.log(
          'Battery Optimization: ${batteryOptimizationDisabled.value}',
          name: _tag,
        );

        // ✅ FIX: Check screen capture permission properly
        screenCaptureGranted.value = await ScreenCaptureService.isSupported();
        developer.log(
          'Screen Capture: ${screenCaptureGranted.value}',
          name: _tag,
        );

        accessibilityGranted.value =
            await ScreenCaptureService.isAccessibilityEnabled();
        developer.log(
          'Accessibility: ${accessibilityGranted.value}',
          name: _tag,
        );
      } else {
        notificationGranted.value = true;
        batteryOptimizationDisabled.value = true;
        screenCaptureGranted.value = true;
        accessibilityGranted.value = false; // iOS doesn't need this
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

  // ✅ FIX: Combined location request (FG + BG)
  Future<bool> requestLocationPermission() async {
    developer.log('========================================', name: _tag);
    developer.log('REQUESTING LOCATION PERMISSIONS', name: _tag);

    currentPermissionIndex.value = 0;
    update(['permission_list', 'progress']);

    // Step 1: Request foreground location
    developer.log('Step 1: Requesting FOREGROUND location...', name: _tag);
    PermissionStatus fgStatus = await Permission.location.request();
    developer.log('Foreground result: $fgStatus', name: _tag);

    if (fgStatus.isDenied || fgStatus.isPermanentlyDenied) {
      developer.log('Foreground location denied', name: _tag);

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
            'Location permission is REQUIRED.\n\n'
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

    // Step 2: Request background location
    developer.log('Step 2: Requesting BACKGROUND location...', name: _tag);

    await Get.dialog(
      barrierDismissible: false,
      AlertDialog(
        title: const Text('Background Location Required'),
        content: const Text(
          'To keep tracking when app is closed, '
          'select "Allow all the time" in the next screen.\n\n'
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

    PermissionStatus bgStatus = await Permission.locationAlways.request();
    developer.log('Background result: $bgStatus', name: _tag);

    if (bgStatus.isDenied || bgStatus.isPermanentlyDenied) {
      developer.log('Background location denied', name: _tag);

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

    // ✅ Check both are granted
    final bothGranted = fgStatus.isGranted && bgStatus.isGranted;
    locationGranted.value = bothGranted;
    update(['permission_list']);

    developer.log('✅ Location permissions: $bothGranted', name: _tag);
    developer.log('========================================', name: _tag);

    return bothGranted;
  }

  // ✅ REMOVE: requestBackgroundLocationPermission() - merged into requestLocationPermission()

  Future<bool> requestCameraPermission() async {
    developer.log('Requesting camera permission...', name: _tag);
    currentPermissionIndex.value = 1;
    update(['permission_list', 'progress']);

    PermissionStatus status = await Permission.camera.request();

    if (status.isPermanentlyDenied || !status.isGranted) {
      await _showSettingsDialog('Camera');
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
    currentPermissionIndex.value = 2;
    update(['permission_list', 'progress']);

    if (Platform.isAndroid) {
      bool alreadyGranted =
          await NotificationListenerService.isPermissionGranted() ?? false;

      if (alreadyGranted) {
        notificationGranted.value = true;
        update(['permission_list']);
        return true;
      }

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
    currentPermissionIndex.value = 3;
    update(['permission_list', 'progress']);

    PermissionStatus status = await Permission.storage.request();

    if (Platform.isAndroid) {
      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted) {
        status = photosStatus;
      }
    }

    if (status.isPermanentlyDenied || !status.isGranted) {
      await _showSettingsDialog('Storage');
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
    currentPermissionIndex.value = 4;
    update(['permission_list', 'progress']);

    if (Platform.isAndroid) {
      await Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: const Text('Battery Optimization Required'),
          content: const Text(
            'You MUST disable battery optimization.\n\n'
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

  // ✅ FIX: Screen capture permission request
  Future<bool> requestScreenCapturePermission() async {
    developer.log('Requesting screen capture permission...', name: _tag);
    currentPermissionIndex.value = 5;
    update(['permission_list', 'progress']);

    if (Platform.isAndroid) {
      // Check if already granted
      final alreadyGranted = await ScreenCaptureService.isSupported();
      if (alreadyGranted) {
        screenCaptureGranted.value = true;
        update(['permission_list']);
        return true;
      }

      // Show explanation dialog
      await Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.screen_share, color: Colors.blue),
              SizedBox(width: 8),
              Text('Screen Capture Required'),
            ],
          ),
          content: const Text(
            'To allow screen capture, you must grant MediaProjection permission.\n\n'
            'Tap "Grant Permission" to continue.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );

      // Request permission
      final granted = await ScreenCaptureService.requestPermission();

      screenCaptureGranted.value = granted;
      update(['permission_list']);

      return granted;
    } else {
      // iOS auto-granted
      screenCaptureGranted.value = true;
      update(['permission_list']);
      return true;
    }
  }

  Future<bool> requestAccessibilityService() async {
    developer.log('Requesting Accessibility Service...', name: _tag);
    currentPermissionIndex.value = 6;
    update(['permission_list', 'progress']);

    if (Platform.isAndroid) {
      // Check if already enabled
      final alreadyEnabled =
          await ScreenCaptureService.isAccessibilityEnabled();
      if (alreadyEnabled) {
        accessibilityGranted.value = true;
        update(['permission_list']);
        return true;
      }

      await Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.accessibility, color: Colors.blue),
              SizedBox(width: 8),
              Text('Accessibility Service Required'),
            ],
          ),
          content: const Text(
            'To allow automatic screen capture, you MUST enable Accessibility Service.\n\n'
            'Tap "Open Settings" and enable the service.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      final intent = AndroidIntent(
        action: 'android.settings.ACCESSIBILITY_SETTINGS',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();

      isWaitingForSettings.value = true;
      await Future.delayed(const Duration(seconds: 2));

      final granted = await ScreenCaptureService.isAccessibilityEnabled();
      accessibilityGranted.value = granted;
      update(['permission_list']);
      return granted;
    }

    return true; // iOS doesn't need this
  }

  Future<void> _showSettingsDialog(String permissionName) async {
    await Get.dialog(
      barrierDismissible: false,
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text('$permissionName Required'),
          ],
        ),
        content: Text(
          '$permissionName permission is REQUIRED.\n\n'
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
  }

  bool areAllPermissionsGranted() {
    final allGranted = Platform.isAndroid
        ? locationGranted.value &&
              cameraGranted.value &&
              notificationGranted.value &&
              storageGranted.value &&
              batteryOptimizationDisabled.value &&
              screenCaptureGranted.value &&
              accessibilityGranted.value
        : locationGranted.value && cameraGranted.value && storageGranted.value;

    developer.log('All permissions granted: $allGranted', name: _tag);
    return allGranted;
  }

  bool areAllCriticalPermissionsGranted() {
    return areAllPermissionsGranted();
  }
}
