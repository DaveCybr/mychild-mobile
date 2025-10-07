import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_endpoints.dart';
import '../../core/constants/app_constants.dart';
import '../local/local_storage_service.dart';

class LocationService {
  static Timer? _locationTimer;
  static final Battery _battery = Battery();
  static late Dio _dio;

  static void startTracking() {
    _locationTimer?.cancel();

    _locationTimer = Timer.periodic(
      Duration(minutes: AppConstants.locationUpdateInterval),
      (_) => _sendLocation(),
    );

    _sendLocation();
  }

  static void stopTracking() {
    _locationTimer?.cancel();
  }

  static Future<void> _sendLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final batteryLevel = await _battery.batteryLevel;
      final deviceId = await LocalStorageService.getDeviceId();
      if (deviceId == null) return;

      await _dio.post(
        ApiEndpoints.sendLocation,
        data: {
          'device_id': deviceId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'battery_level': batteryLevel,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to send location: $e');
    }
  }

  static Future<void> sendImmediateLocation() async {
    await _sendLocation();
  }
}
