import 'dart:io';

import 'package:couple_guard_child/utils/local_storage.dart';
import 'package:couple_guard_child/utils/native_bridge.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;
import '../../models/pairing_response_model.dart';

class DeviceService extends GetxService {
  static const String _tag = 'DeviceService';
  static const String _baseUrl =
      'https://parentalcontrol.satelliteorbit.cloud/api';

  late final Dio _dio;

  @override
  void onInit() {
    super.onInit();
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          developer.log('→ ${options.method} ${options.path}', name: _tag);
          developer.log('  Headers: ${options.headers}', name: _tag);
          if (options.data != null) {
            developer.log('  Body: ${options.data}', name: _tag);
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          developer.log(
            '← ${response.statusCode} ${response.requestOptions.path}',
            name: _tag,
          );
          developer.log('  Response: ${response.data}', name: _tag);
          return handler.next(response);
        },
        onError: (error, handler) {
          developer.log('❌ ${error.requestOptions.path}', name: _tag);
          developer.log('  Error: ${error.message}', name: _tag);
          if (error.response != null) {
            developer.log('  Response: ${error.response?.data}', name: _tag);
          }
          return handler.next(error);
        },
      ),
    );
  }

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

  /// Get device name from hardware
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

  /// Pair device with family code
  Future<PairingResponseModel> pairDevice(String familyCode) async {
    try {
      developer.log('========================================', name: _tag);
      developer.log('🔗 Pairing device with code: $familyCode', name: _tag);

      // Get device ID from SharedPreferences
      final deviceId = await getDeviceId();

      if (deviceId.isEmpty) {
        developer.log('❌ No device ID found', name: _tag, level: 900);
        return PairingResponseModel(
          success: false,
          message: 'Device ID not found. Please restart the app.',
        );
      }

      developer.log('Device ID: ${deviceId.substring(0, 8)}...', name: _tag);

      final response = await _dio.post(
        '/devices/pair',
        data: {
          'family_code': familyCode.toUpperCase(),
          'device_id': deviceId,
          'device_name': 'Android Device', // You can get actual device name
          'device_type': 'android',
        },
      );

      developer.log('Response status: ${response.statusCode}', name: _tag);

      final pairingResponse = PairingResponseModel.fromJson(response.data);

      if (pairingResponse.success) {
        developer.log('✅ Pairing successful', name: _tag);
      } else {
        developer.log(
          '❌ Pairing failed: ${pairingResponse.message}',
          name: _tag,
        );
      }

      developer.log('========================================', name: _tag);
      return pairingResponse;
    } on DioException catch (e) {
      developer.log('❌ DioException during pairing', name: _tag, error: e);

      if (e.response != null) {
        // Server responded with error
        try {
          final errorData = e.response!.data;
          developer.log('Server error response: $errorData', name: _tag);

          return PairingResponseModel(
            success: false,
            message: errorData['message'] ?? 'Invalid family code',
          );
        } catch (_) {
          return PairingResponseModel(
            success: false,
            message: 'Server error: ${e.response!.statusCode}',
          );
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return PairingResponseModel(
          success: false,
          message: 'Connection timeout. Please check your internet.',
        );
      } else if (e.type == DioExceptionType.unknown) {
        return PairingResponseModel(
          success: false,
          message: 'No internet connection.',
        );
      } else {
        return PairingResponseModel(
          success: false,
          message: 'Network error. Please try again.',
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Unexpected error during pairing',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
      );

      return PairingResponseModel(
        success: false,
        message: 'An unexpected error occurred.',
      );
    }
  }

  Future<bool> unpairDevice() async {
    try {
      final deviceId = await getDeviceId();

      developer.log('Unpairing device: $deviceId', name: _tag);

      final response = await _dio.post(
        '/devices/unpair',
        data: {'device_id': deviceId},
      );

      if (response.data['success'] == true) {
        developer.log('✅ Device unpaired successfully', name: _tag);
        return true;
      }

      return false;
    } catch (e) {
      developer.log(
        '❌ Failed to unpair device',
        name: _tag,
        error: e,
        level: 1000,
      );
      return false;
    }
  }

  /// Update FCM token
  Future<bool> updateFcmToken(String fcmToken) async {
    try {
      developer.log('🔑 Updating FCM token', name: _tag);

      final deviceId = await LocalStorageService.getDeviceId();

      if (deviceId == null || deviceId.isEmpty) {
        developer.log('❌ No device ID found', name: _tag);
        return false;
      }

      developer.log('Token: ${fcmToken.substring(0, 20)}...', name: _tag);

      final response = await _dio.post(
        '/devices/update-fcm-token',
        data: {'device_id': deviceId, 'fcm_token': fcmToken},
      );

      if (response.statusCode == 200) {
        developer.log('✅ FCM token updated successfully', name: _tag);

        // Save token locally
        await LocalStorageService.saveFcmToken(fcmToken);

        return true;
      } else {
        developer.log(
          '❌ Failed to update FCM token: ${response.statusCode}',
          name: _tag,
        );
        return false;
      }
    } on DioException catch (e) {
      developer.log('❌ DioException updating FCM token', name: _tag, error: e);
      return false;
    } catch (e) {
      developer.log('❌ Error updating FCM token', name: _tag, error: e);
      return false;
    }
  }

  /// Send location to server
  Future<bool> sendLocation({
    required double latitude,
    required double longitude,
    required int batteryLevel,
  }) async {
    try {
      final deviceId = await LocalStorageService.getDeviceId();

      if (deviceId == null) {
        developer.log('❌ No device ID for location update', name: _tag);
        return false;
      }

      final response = await _dio.post(
        '/device/locations',
        data: {
          'device_id': deviceId,
          'latitude': latitude,
          'longitude': longitude,
          'battery_level': batteryLevel,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      developer.log('❌ Error sending location', name: _tag, error: e);
      return false;
    }
  }

  /// Send notification to server
  Future<bool> sendNotification({
    required String appName,
    required String title,
    required String content,
  }) async {
    try {
      final deviceId = await LocalStorageService.getDeviceId();

      if (deviceId == null) {
        developer.log('❌ No device ID for notification', name: _tag);
        return false;
      }

      final response = await _dio.post(
        '/device/notifications',
        data: {
          'device_id': deviceId,
          'app_name': appName,
          'title': title,
          'content': content,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      developer.log('❌ Error sending notification', name: _tag, error: e);
      return false;
    }
  }

  /// Update device status (online/offline)
  Future<bool> updateDeviceStatus(bool isOnline) async {
    try {
      final deviceId = await LocalStorageService.getDeviceId();

      if (deviceId == null) {
        return false;
      }

      final response = await _dio.put(
        '/device/$deviceId/status',
        data: {'is_online': isOnline},
      );

      return response.statusCode == 200;
    } catch (e) {
      developer.log('Error updating device status', name: _tag, error: e);
      return false;
    }
  }
}
