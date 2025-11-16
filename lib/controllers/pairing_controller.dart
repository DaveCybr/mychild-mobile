import 'package:couple_guard_child/services/device_service.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../utils/local_storage.dart';
import 'dart:developer' as developer;

class PairingController extends GetxController {
  static const String _tag = 'PairingController';
  static const _platform = MethodChannel('location_worker_channel');

  DeviceService get _deviceService => Get.find<DeviceService>();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString familyCode = ''.obs;

  @override
  void onInit() {
    super.onInit();
    developer.log('✅ PairingController initialized', name: _tag);
  }

  /// Pair device with family code
  Future<bool> pairDevice(String code) async {
    developer.log('========================================', name: _tag);
    developer.log('🔗 pairDevice called with code: $code', name: _tag);

    // Validation
    if (code.isEmpty || code.length != 6) {
      final error = 'Please enter a valid 6-character family code';
      developer.log('❌ Validation failed: $error', name: _tag, level: 900);
      errorMessage.value = error;
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Step 1: Call API to pair device
      developer.log('Step 1: Calling API to pair device', name: _tag);
      final response = await _deviceService.pairDevice(code.toUpperCase());

      developer.log('API Response - Success: ${response.success}', name: _tag);

      if (!response.success) {
        developer.log(
          '❌ Pairing failed: ${response.message}',
          name: _tag,
          level: 900,
        );
        errorMessage.value = response.message;
        return false;
      }

      // Step 2: Save to local storage
      developer.log('Step 2: Saving device info to local storage', name: _tag);

      if (response.device == null) {
        developer.log('❌ No device data in response', name: _tag, level: 900);
        errorMessage.value = 'Invalid response from server';
        return false;
      }

      await LocalStorageService.saveDeviceInfo(
        deviceId: response.device!.deviceId,
        familyCode: code.toUpperCase(),
        parentId: response.device!.parentId ?? 0,
        deviceName: response.device!.deviceName,
      );

      familyCode.value = code.toUpperCase();

      developer.log('✅ Device info saved locally', name: _tag);
      developer.log('  DeviceId: ${response.device!.deviceId}', name: _tag);
      developer.log('  ParentId: ${response.device!.parentId}', name: _tag);
      developer.log('  FamilyCode: ${code.toUpperCase()}', name: _tag);

      // Step 3: Start WorkManager (will be called from PairingScreen after FCM token update)
      // We'll let PairingScreen handle this to ensure FCM token is updated first

      developer.log('✅ Pairing completed successfully', name: _tag);
      developer.log('========================================', name: _tag);

      return true;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Exception during pairing',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      errorMessage.value = 'Failed to pair device. Please try again.';
      developer.log('========================================', name: _tag);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Start WorkManager for periodic location tracking
  Future<bool> startPeriodicLocation() async {
    try {
      developer.log(
        '🚀 Starting WorkManager for location tracking',
        name: _tag,
      );
      await _platform.invokeMethod('startPeriodicLocation');
      developer.log('✅ WorkManager started successfully', name: _tag);
      return true;
    } catch (e) {
      developer.log('❌ Failed to start WorkManager', name: _tag, error: e);
      return false;
    }
  }

  void clearError() {
    developer.log('🗑️ Error message cleared', name: _tag);
    errorMessage.value = '';
  }

  @override
  void onClose() {
    developer.log('🔚 PairingController disposed', name: _tag);
    super.onClose();
  }
}
