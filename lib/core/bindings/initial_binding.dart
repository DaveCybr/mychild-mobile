import 'package:get/get.dart';
import '../../services/api/api_service.dart';
import '../../services/api/device_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize ApiService synchronously first
    final apiService = ApiService();
    Get.put<ApiService>(apiService, permanent: true);

    // Then initialize it async in background
    apiService.init();

    // DeviceService can now safely access ApiService
    Get.put<DeviceService>(DeviceService(), permanent: true);
  }
}
