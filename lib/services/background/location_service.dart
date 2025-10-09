// services/background/location_service.dart - FIXED VERSION
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import '../../core/constants/app_endpoints.dart';
import '../../core/constants/app_constants.dart';
import '../local/local_storage_service.dart';

class LocationService {
  static const String _tag = 'LocationService';

  static Timer? _locationTimer;
  static final Battery _battery = Battery();

  // ✅ FIX: Initialize langsung
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static bool _isSending = false;

  // ✅ Remove lazy getter, langsung akses _dio

  static void startTracking() {
    developer.log('STARTING LOCATION TRACKING', name: _tag);
    _locationTimer?.cancel();

    _locationTimer = Timer.periodic(
      Duration(minutes: AppConstants.locationUpdateInterval),
      (_) => _sendLocation(),
    );

    _sendLocation();
  }

  static void stopTracking() {
    developer.log('Stopping location tracking', name: _tag);
    _locationTimer?.cancel();
    _locationTimer = null;
    _isSending = false;
  }

  static Future<void> _sendLocation() async {
    if (_isSending) {
      developer.log('⏭️ Location send already in progress', name: _tag);
      return;
    }

    _isSending = true;

    try {
      developer.log('Checking location permission...', name: _tag);

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        developer.log('❌ Location permission denied', name: _tag, level: 900);
        return;
      }

      developer.log('Getting current position...', name: _tag);

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      developer.log(
        'Position: ${position.latitude}, ${position.longitude}',
        name: _tag,
      );

      final batteryLevel = await _battery.batteryLevel;
      developer.log('Battery: $batteryLevel%', name: _tag);

      final deviceId = await LocalStorageService.getDeviceId();
      if (deviceId == null) {
        developer.log('❌ Device ID not found', name: _tag, level: 900);
        return;
      }

      developer.log('Sending location to server...', name: _tag);

      // ✅ FIX: Langsung pakai _dio (sudah initialize)
      final response = await _dio.post(
        ApiEndpoints.sendLocation,
        data: {
          'device_id': deviceId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'battery_level': batteryLevel,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        developer.log('✅ Location sent successfully', name: _tag);
      } else {
        developer.log(
          '⚠️ Server returned: ${response.statusCode}',
          name: _tag,
          level: 900,
        );
      }
    } on TimeoutException catch (e) {
      developer.log('⏱️ Location timeout', name: _tag, error: e, level: 900);
    } on DioException catch (e) {
      developer.log(
        '❌ Network error sending location',
        name: _tag,
        error: e,
        level: 900,
      );
    } catch (e, stack) {
      developer.log(
        '❌ Failed to send location',
        name: _tag,
        error: e,
        stackTrace: stack,
        level: 1000,
      );
    } finally {
      _isSending = false;
    }
  }

  static Future<void> sendImmediateLocation() async {
    developer.log('📍 Immediate location request', name: _tag);
    await _sendLocation();
  }

  static bool get isTracking =>
      _locationTimer != null && _locationTimer!.isActive;
}
