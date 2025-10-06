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
      final url = Uri.parse('$baseUrl/device/locations');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'device_id': deviceId,
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Location API: ${response.statusCode}');

      if (response.statusCode == 201) {
        print('Location sent successfully');
        return true;
      } else {
        print('Failed to send location: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending location: $e');
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
      final url = Uri.parse('$baseUrl/device/notifications');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'device_id': deviceId,
              'app_name': appName,
              'title': title,
              'content': content,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Notification API: ${response.statusCode}');

      if (response.statusCode == 201) {
        print('Notification sent successfully');
        return true;
      } else {
        print('Failed to send notification: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }
}
