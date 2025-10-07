// controllers/pairing_controller.dart
import 'package:get/get.dart';
import '../services/api/device_service.dart';
import '../services/local/local_storage_service.dart';
import 'dart:developer' as developer;

class PairingController extends GetxController {
  static const String _tag = 'PairingController';

  // Use lazy getter instead of eager initialization
  DeviceService get _deviceService => Get.find<DeviceService>();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString familyCode = ''.obs;

  @override
  void onInit() {
    super.onInit();
    developer.log('Controller initialized', name: _tag);
  }

  Future<bool> pairDevice(String code) async {
    developer.log(
      'pairDevice called with code length: ${code.length}',
      name: _tag,
    );

    if (code.isEmpty || code.length != 6) {
      final error = 'Please enter a valid 6-character family code';
      developer.log('Validation failed: $error', name: _tag, level: 900);
      errorMessage.value = error;
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';
    developer.log(
      'Starting pairing process for code: ${code.toUpperCase()}',
      name: _tag,
    );

    try {
      final response = await _deviceService.pairDevice(code.toUpperCase());
      developer.log(
        'API response received - success: ${response.success}',
        name: _tag,
      );

      if (response.success) {
        familyCode.value = code.toUpperCase();
        developer.log(
          'Pairing successful - DeviceId: ${response.device!.deviceId}, ParentId: ${response.device!.parentId}',
          name: _tag,
        );

        await LocalStorageService.saveDeviceInfo(
          deviceId: response.device!.deviceId,
          familyCode: code.toUpperCase(),
          parentId: response.device!.parentId ?? 0,
        );
        developer.log('Device info saved to local storage', name: _tag);

        Get.snackbar(
          'Success',
          'Device paired successfully!',
          snackPosition: SnackPosition.TOP,
        );

        return true;
      } else {
        developer.log(
          'Pairing failed: ${response.message}',
          name: _tag,
          level: 900,
        );
        errorMessage.value = response.message;
        return false;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Exception during pairing',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      errorMessage.value =
          'Failed to pair device. Please check the code and try again.';
      return false;
    } finally {
      isLoading.value = false;
      developer.log('Pairing process completed', name: _tag);
    }
  }

  void clearError() {
    developer.log('Error message cleared', name: _tag);
    errorMessage.value = '';
  }

  @override
  void onClose() {
    developer.log('Controller disposed', name: _tag);
    super.onClose();
  }
}
