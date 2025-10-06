// services/background/location_service.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:get/get.dart';
import '../../core/constants/app_endpoints.dart';
import '../../core/constants/app_constants.dart';
import '../api/api_service.dart';
import '../local/local_storage_service.dart';

class LocationService {
  static Timer? _locationTimer;
  static final Battery _battery = Battery();
  static void startTracking() {
    _locationTimer?.cancel();

    // schedule timer seperti biasa
    _locationTimer = Timer.periodic(
      Duration(minutes: AppConstants.locationUpdateInterval),
      (_) => _sendLocation(),
    );

    // Jangan langsung memanggil _sendLocation() synchronously — pindahkan ke microtask
    // agar tidak memblokir onStart. caller harus memastikan permission sudah granted.
    Future.microtask(() async {
      try {
        // cek permission dulu tanpa memaksa request UI
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          developer.log(
            'Location permission not granted, skipping initial send',
            name: 'LocationService',
          );
          return;
        }
        await _sendLocation();
      } catch (e) {
        developer.log(
          'Initial sendLocation failed: $e',
          name: 'LocationService',
        );
      }
    });
  }

  static void stopTracking() {
    _locationTimer?.cancel();
  }

  // Di bagian _sendLocation()
  static Future<void> _sendLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get battery level
      final batteryLevel = await _battery.batteryLevel;

      // Get device ID
      final deviceId = await LocalStorageService.getDeviceId();
      if (deviceId == null) return;

      // Get ApiService lazily
      final apiService = Get.find<ApiService>();

      await apiService.post(
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
