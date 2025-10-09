// services/background/location_service.dart - FIXED
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

  // ✅ FIX: Initialize Dio properly
  static Dio? _dio;

  static Dio get dio {
    _dio ??= Dio(
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
    return _dio!;
  }

  static void startTracking() {
    developer.log('========================================', name: _tag);
    developer.log('STARTING LOCATION TRACKING', name: _tag);

    _locationTimer?.cancel();

    // ✅ Send immediately on start
    _sendLocation();

    // ✅ Then send periodically
    _locationTimer = Timer.periodic(
      Duration(minutes: AppConstants.locationUpdateInterval),
      (_) {
        developer.log('⏰ Periodic location update triggered', name: _tag);
        _sendLocation();
      },
    );

    developer.log('✅ Location tracking started', name: _tag);
    developer.log(
      'Update interval: ${AppConstants.locationUpdateInterval} minutes',
      name: _tag,
    );
    developer.log('========================================', name: _tag);
  }

  static void stopTracking() {
    developer.log('Stopping location tracking', name: _tag);
    _locationTimer?.cancel();
    _locationTimer = null;
    developer.log('✅ Location tracking stopped', name: _tag);
  }

  static Future<void> _sendLocation() async {
    developer.log('========================================', name: _tag);
    developer.log('📍 SENDING LOCATION UPDATE', name: _tag);

    try {
      // ✅ Check permission first
      LocationPermission permission = await Geolocator.checkPermission();
      developer.log('Location permission: $permission', name: _tag);

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        developer.log('❌ Location permission denied', name: _tag, level: 900);
        return;
      }

      // ✅ Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        developer.log('❌ Location service disabled', name: _tag, level: 900);
        return;
      }

      // ✅ Get current position
      developer.log('Getting current position...', name: _tag);
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15), // Add timeout
      );

      developer.log(
        'Position: ${position.latitude}, ${position.longitude}',
        name: _tag,
      );

      // ✅ Get battery level
      final batteryLevel = await _battery.batteryLevel;
      developer.log('Battery: $batteryLevel%', name: _tag);

      // ✅ Get device ID
      final deviceId = await LocalStorageService.getDeviceId();
      if (deviceId == null || deviceId.isEmpty) {
        developer.log('❌ Device ID not found', name: _tag, level: 900);
        return;
      }

      developer.log('Device ID: ${deviceId.substring(0, 8)}...', name: _tag);

      // ✅ Prepare payload
      final payload = {
        'device_id': deviceId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'battery_level': batteryLevel,
        'timestamp': DateTime.now().toIso8601String(),
      };

      developer.log('Payload: $payload', name: _tag);

      // ✅ Send to server
      developer.log('Sending to server...', name: _tag);
      final response = await dio.post(ApiEndpoints.sendLocation, data: payload);

      developer.log('✅ Server response: ${response.statusCode}', name: _tag);
      developer.log('Response data: ${response.data}', name: _tag);
    } on TimeoutException catch (e) {
      developer.log(
        '⏱️ Timeout getting location',
        name: _tag,
        error: e,
        level: 900,
      );
    } on DioException catch (e) {
      developer.log(
        '❌ Network error sending location',
        name: _tag,
        error: e.message,
        level: 900,
      );
      if (e.response != null) {
        developer.log('Response: ${e.response?.data}', name: _tag, level: 900);
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to send location',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }

    developer.log('========================================', name: _tag);
  }

  /// ✅ Send location immediately (triggered by parent command)
  static Future<void> sendImmediateLocation() async {
    developer.log('📍 IMMEDIATE location request', name: _tag);
    await _sendLocation();
  }

  /// ✅ Check if tracking is active
  static bool get isTracking =>
      _locationTimer != null && _locationTimer!.isActive;
}
