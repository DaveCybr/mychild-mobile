// File: lib/test_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'test_device_service.dart';

class ApiService {
  static const String baseUrl =
      'https://parentalcontrol.satelliteorbit.cloud/api';

  /// Send location to server
  static Future<bool> sendLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      print('📍 Sending location with Device ID: $deviceId');

      final url = Uri.parse('$baseUrl/device/locations');

      final payload = {
        'device_id': deviceId,
        'latitude': latitude,
        'longitude': longitude,
      };

      print('📍 Location Payload: ${jsonEncode(payload)}');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      print('📍 Location API Response: ${response.statusCode}');
      print('📍 Location Response Body: ${response.body}');

      if (response.statusCode == 201) {
        print('✅ Location sent successfully');
        return true;
      } else {
        print('❌ Failed to send location: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending location: $e');
      return false;
    }
  }

  /// Send notification to server
  static Future<bool> sendNotification({
    required String appName,
    required String title,
    required String content,
  }) async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      print('🔔 Sending notification with Device ID: $deviceId');

      final url = Uri.parse('$baseUrl/device/notifications');

      final payload = {
        'device_id': deviceId,
        'app_name': appName,
        'title': title,
        'content': content,
      };

      print('🔔 Notification Payload: ${jsonEncode(payload)}');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      print('🔔 Notification API Response: ${response.statusCode}');
      print('🔔 Notification Response Body: ${response.body}');

      if (response.statusCode == 201) {
        print('✅ Notification sent successfully');
        return true;
      } else {
        print('❌ Failed to send notification: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending notification: $e');
      return false;
    }
  }

  /// Test notification API directly
  static Future<Map<String, dynamic>> testNotificationAPI() async {
    try {
      final deviceId = await DeviceService.getDeviceId();

      final result = await sendNotification(
        appName: 'com.test.app',
        title: 'Test Notification',
        content: 'This is a test notification from Flutter',
      );

      return {
        'success': result,
        'device_id': deviceId,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Test location API directly
  static Future<Map<String, dynamic>> testLocationAPI() async {
    try {
      final deviceId = await DeviceService.getDeviceId();

      final result = await sendLocation(
        latitude: -8.1234567,
        longitude: 113.1234567,
      );

      return {
        'success': result,
        'device_id': deviceId,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
