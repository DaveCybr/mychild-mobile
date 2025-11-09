import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import '../local/local_storage_service.dart';

class ScreenCaptureService {
  static const String _tag = 'ScreenCaptureService';

  // ✅ CRITICAL: Use correct channel name
  static const _platform = MethodChannel('screen_capture_permission_channel');

  /// Initialize service
  static Future<void> initialize() async {
    try {
      developer.log('Initializing screen capture service...', name: _tag);
      developer.log('✅ Screen capture service initialized', name: _tag);
    } catch (e) {
      developer.log(
        '❌ Failed to initialize screen capture service',
        name: _tag,
        error: e,
      );
    }
  }

  /// Check if permission was granted (dari native side)
  static Future<bool> isSupported() async {
    try {
      if (Platform.isAndroid) {
        // ✅ Check via MethodChannel
        final bool? hasPermission = await _platform.invokeMethod<bool>(
          'isProjectionActive',
        );

        developer.log('Screen capture permission: $hasPermission', name: _tag);
        return hasPermission ?? false;
      } else {
        // iOS - screenshot package doesn't need permission
        return true;
      }
    } catch (e) {
      developer.log(
        'Error checking screen capture permission',
        name: _tag,
        error: e,
      );
      return false;
    }
  }

  /// Request permission (launch native activity)
  static Future<bool> requestPermission() async {
    developer.log('========================================', name: _tag);
    developer.log('Requesting screen capture permission...', name: _tag);

    try {
      if (Platform.isAndroid) {
        // ✅ Call native method to launch permission activity
        developer.log(
          'Calling native requestScreenCapturePermission...',
          name: _tag,
        );

        final bool? result = await _platform.invokeMethod<bool>(
          'requestScreenCapturePermission',
        );

        developer.log('Native method returned: $result', name: _tag);

        if (result == true) {
          // ✅ Wait a bit for native to save to SharedPreferences
          await Future.delayed(const Duration(milliseconds: 1000));

          // ✅ Verify permission was saved
          final verified = await isSupported();
          developer.log('Permission verification: $verified', name: _tag);

          if (verified) {
            developer.log('✅ Screen capture permission GRANTED', name: _tag);
            developer.log(
              '========================================',
              name: _tag,
            );
            return true;
          } else {
            developer.log(
              '❌ Permission granted but not saved correctly!',
              name: _tag,
              level: 900,
            );
            developer.log(
              '========================================',
              name: _tag,
            );
            return false;
          }
        } else {
          developer.log('❌ Screen capture permission DENIED', name: _tag);
          developer.log('========================================', name: _tag);
          return false;
        }
      } else {
        // iOS - no permission needed
        developer.log('✅ Screen capture permission granted (iOS)', name: _tag);
        developer.log('========================================', name: _tag);
        return true;
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error requesting screen capture permission',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      developer.log('========================================', name: _tag);
      return false;
    }
  }

  /// Clear permission (for testing/reset)
  static Future<void> clearPermission() async {
    try {
      // Clear local storage flag
      await LocalStorageService.setScreenCapturePermission(false);

      // ✅ Also clear native side
      if (Platform.isAndroid) {
        try {
          await _platform.invokeMethod('clearScreenCapturePermission');
        } catch (e) {
          developer.log(
            'Failed to clear native permission',
            name: _tag,
            error: e,
          );
        }
      }

      developer.log('Screen capture permission cleared', name: _tag);
    } catch (e) {
      developer.log('Error clearing permission', name: _tag, error: e);
    }
  }
}
