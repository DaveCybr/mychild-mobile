import 'package:get/get.dart';
import '../../services/api/api_service.dart';
import '../../services/api/device_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ApiService>(ApiService(), permanent: true);
    Get.put<DeviceService>(DeviceService(), permanent: true);
  }
}
