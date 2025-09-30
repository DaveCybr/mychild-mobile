// controllers/pairing_controller.dart
import 'package:get/get.dart';
import '../services/api/device_service.dart';
import '../services/local/local_storage_service.dart';

class PairingController extends GetxController {
  final DeviceService _deviceService = Get.put(DeviceService());

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString familyCode = ''.obs;

  Future<bool> pairDevice(String code) async {
    if (code.isEmpty || code.length != 8) {
      errorMessage.value = 'Please enter a valid 8-character family code';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await _deviceService.pairDevice(code.toUpperCase());

      if (response.success) {
        familyCode.value = code.toUpperCase();
        await LocalStorageService.saveDeviceInfo(
          deviceId: response.device!.deviceId,
          familyCode: code.toUpperCase(),
          parentId: response.device!.parentId,
        );

        Get.snackbar(
          'Success',
          'Device paired successfully!',
          snackPosition: SnackPosition.TOP,
        );

        return true;
      } else {
        errorMessage.value = response.message;
        return false;
      }
    } catch (e) {
      errorMessage.value =
          'Failed to pair device. Please check the code and try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void clearError() {
    errorMessage.value = '';
  }
}
