import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'test_api_service.dart';

class NotificationListenerService {
  static const MethodChannel _channel = MethodChannel(
    'notification_listener_channel',
  );

  static File? _notifLogFile;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _notifLogFile = File('${dir.path}/notifications_log.txt');
    if (!(await _notifLogFile!.exists())) {
      await _notifLogFile!.create(recursive: true);
    }

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNotificationReceived') {
        try {
          final Map<dynamic, dynamic> args = call.arguments;
          final packageName = args['package']?.toString() ?? '';
          final title = args['title']?.toString() ?? '';
          final text = args['text']?.toString() ?? '';
          final timestamp = args['timestamp']?.toString() ?? '';

          final logLine =
              "[${DateTime.now().toIso8601String()}] NOTIF from=$packageName title='$title' text='$text' ts=$timestamp";
          print(logLine);

          // Save to file
          if (_notifLogFile != null) {
            await _notifLogFile!.writeAsString(
              "$logLine\n",
              mode: FileMode.append,
            );
          }

          // Send to server
          await ApiService.sendNotification(
            appName: packageName,
            title: title,
            content: text,
          );
        } catch (e) {
          print('NotificationListenerService handler error: $e');
        }
      }
    });

    print('NotificationListenerService initialized');
  }

  /// Check if notification permission is granted
  static Future<bool> isPermissionGranted() async {
    try {
      final result = await _channel.invokeMethod('checkNotificationPermission');
      return result as bool;
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }

  /// Open notification listener settings
  static Future<void> openSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (e) {
      print('Error opening settings: $e');
    }
  }

  /// Read log file
  static Future<String> readLog() async {
    if (_notifLogFile == null) {
      await init();
    }

    if (await _notifLogFile!.exists()) {
      return _notifLogFile!.readAsString();
    }
    return 'No logs yet';
  }

  /// Clear log file
  static Future<void> clearLog() async {
    if (_notifLogFile != null && await _notifLogFile!.exists()) {
      await _notifLogFile!.writeAsString('');
    }
  }
}
