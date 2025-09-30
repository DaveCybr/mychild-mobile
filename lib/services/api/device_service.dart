import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../core/constants/app_endpoints.dart';
import '../../models/pairing_response_model.dart';
import 'api_service.dart';
import '../local/local_storage_service.dart';

class DeviceService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? '';
    }

    return deviceId;
  }

  Future<String> getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceName = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceName = '${androidInfo.brand} ${androidInfo.model}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceName = iosInfo.name;
    }

    return deviceName;
  }

  Future<PairingResponseModel> pairDevice(String familyCode) async {
    try {
      final deviceId = await getDeviceId();
      final deviceName = await getDeviceName();
      final deviceType = Platform.isAndroid ? 'android' : 'ios';

      final response = await _apiService.post(
        ApiEndpoints.pairDevice,
        data: {
          'family_code': familyCode,
          'device_id': deviceId,
          'device_name': deviceName,
          'device_type': deviceType,
        },
      );

      final pairingResponse = PairingResponseModel.fromJson(response.data);

      if (pairingResponse.success && pairingResponse.device != null) {
        // Save device info locally
        await LocalStorageService.saveDeviceInfo(
          deviceId: deviceId,
          familyCode: familyCode,
          parentId: pairingResponse.device!.parentId,
        );
      }

      return pairingResponse;
    } catch (e) {
      throw Exception('Failed to pair device: $e');
    }
  }

  Future<void> updateDeviceStatus(bool isOnline) async {
    try {
      final deviceId = await LocalStorageService.getDeviceId();
      if (deviceId == null) return;

      await _apiService.put(
        ApiEndpoints.updateStatus.replaceAll(':deviceId', deviceId),
        data: {'is_online': isOnline},
      );
    } catch (e) {
      print('Failed to update device status: $e');
    }
  }
}
