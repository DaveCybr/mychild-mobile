import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'dart:developer' as developer;
import '../../core/constants/app_endpoints.dart';
import '../../models/pairing_response_model.dart';
import 'api_service.dart';
import '../local/local_storage_service.dart';

class DeviceService extends GetxService {
  static const String _tag = 'DeviceService';

  // Lazy getter instead of eager initialization
  ApiService get _apiService => Get.find<ApiService>();

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

  /// BARU: Verify apakah device sudah paired di server
  Future<Map<String, dynamic>?> verifyPairing() async {
    try {
      final deviceId = await getDeviceId();

      developer.log('Verifying pairing for device: $deviceId', name: _tag);

      final response = await _apiService.post(
        ApiEndpoints.verifyDevice,
        data: {'device_id': deviceId},
      );

      developer.log('Verify response: ${response.data}', name: _tag);

      if (response.data['success'] == true &&
          response.data['is_paired'] == true) {
        final deviceData = response.data['data'];

        // Sync local storage dengan data dari server
        await LocalStorageService.saveDeviceInfo(
          deviceId: deviceData['device_id'],
          familyCode: deviceData['family_code'],
          parentId: deviceData['parent_id'],
        );

        developer.log('Device is paired, synced with server data', name: _tag);

        return deviceData;
      }

      developer.log('Device not paired on server', name: _tag);

      return null;
    } catch (e) {
      developer.log(
        'Failed to verify pairing',
        name: _tag,
        error: e,
        level: 900,
      );
      return null;
    }
  }

  /// BARU: Unpair device dari server dan local storage
  Future<bool> unpairDevice() async {
    try {
      final deviceId = await getDeviceId();

      developer.log('Unpairing device: $deviceId', name: _tag);

      final response = await _apiService.post(
        ApiEndpoints.unpairDevice,
        data: {'device_id': deviceId},
      );

      if (response.data['success'] == true) {
        // Clear local storage
        await LocalStorageService.clearPairing();

        developer.log('Device unpaired successfully', name: _tag);

        return true;
      }

      return false;
    } catch (e) {
      developer.log(
        'Failed to unpair device',
        name: _tag,
        error: e,
        level: 1000,
      );
      return false;
    }
  }

  Future<PairingResponseModel> pairDevice(String familyCode) async {
    try {
      final deviceId = await getDeviceId();
      final deviceName = await getDeviceName();
      final deviceType = Platform.isAndroid ? 'android' : 'ios';

      developer.log('Attempting to pair device: $deviceId', name: _tag);

      final response = await _apiService.post(
        ApiEndpoints.pairDevice,
        data: {
          'family_code': familyCode,
          'device_id': deviceId,
          'device_name': deviceName,
          'device_type': deviceType,
        },
      );

      developer.log('Pair response: ${response.data}', name: _tag);

      final pairingResponse = PairingResponseModel.fromJson(response.data);

      if (pairingResponse.success && pairingResponse.device != null) {
        await LocalStorageService.saveDeviceInfo(
          deviceId: deviceId,
          familyCode: familyCode,
          parentId: pairingResponse.device!.parentId ?? 0,
        );

        developer.log('Device paired and saved to local storage', name: _tag);
      }

      return pairingResponse;
    } catch (e) {
      developer.log('Failed to pair device', name: _tag, error: e, level: 1000);
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
      developer.log(
        'Failed to update device status',
        name: _tag,
        error: e,
        level: 900,
      );
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      final deviceId = await LocalStorageService.getDeviceId();
      if (deviceId == null) return;

      await _apiService.post(
        ApiEndpoints.sendLocation,
        data: {
          'device_id': deviceId,
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      developer.log(
        'Failed to update location',
        name: _tag,
        error: e,
        level: 900,
      );
    }
  }
}
