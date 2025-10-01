import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_screen_capture/flutter_screen_capture.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;

import '../../core/constants/app_endpoints.dart';
import '../../core/constants/app_constants.dart';
import '../api/api_service.dart';
import '../local/local_storage_service.dart';

class ScreenMonitorService {
  static const String _tag = 'ScreenMonitorService';

  static Timer? _checkTimer;
  static Timer? _streamTimer;
  static bool _isStreaming = false;
  static String? _currentSessionToken;
  static int _frameCounter = 0;

  /// Mulai monitoring
  static void startMonitoring() {
    developer.log('Starting screen monitoring', name: _tag);

    _checkTimer?.cancel();

    _checkTimer = Timer.periodic(
      Duration(seconds: AppConstants.screenCheckInterval),
      (_) => _checkForActiveSession(),
    );

    // Initial check dengan delay untuk memastikan app sudah siap
    Future.delayed(const Duration(seconds: 3), () {
      _checkForActiveSession();
    });
  }

  /// Hentikan monitoring
  static void stopMonitoring() {
    developer.log('Stopping screen monitoring', name: _tag);

    _checkTimer?.cancel();
    stopStreaming();
  }

  /// Cek ke server apakah ada sesi aktif
  static Future<void> _checkForActiveSession() async {
    try {
      final childId = await LocalStorageService.getChildId();
      if (childId == null) {
        developer.log(
          'Child ID not found, skipping session check',
          name: _tag,
          level: 900,
        );
        return;
      }

      // Get ApiService lazily
      final apiService = Get.find<ApiService>();

      final response = await apiService.get(
        ApiEndpoints.checkActiveSession.replaceAll(':childId', childId),
      );

      final isBeingMonitored = response.data['is_being_monitored'] ?? false;
      final activeSession = response.data['active_session'];

      developer.log(
        'Session check result - Being monitored: $isBeingMonitored',
        name: _tag,
      );

      if (isBeingMonitored && !_isStreaming && activeSession != null) {
        _currentSessionToken = activeSession['session_token'];
        developer.log(
          'Starting stream for session: $_currentSessionToken',
          name: _tag,
        );
        await startStreaming();
      } else if (!isBeingMonitored && _isStreaming) {
        developer.log('Stopping stream - no active session', name: _tag);
        stopStreaming();
      }
    } on Exception catch (e) {
      // Handle 404 dan error lainnya dengan graceful
      if (e.toString().contains('404')) {
        developer.log(
          'No active session found (404) - This is normal',
          name: _tag,
        );
      } else {
        developer.log(
          'Failed to check active session',
          name: _tag,
          error: e,
          level: 900,
        );
      }
    }
  }

  static Future<void> _sendFrame() async {
    if (!_isStreaming || _currentSessionToken == null) return;

    try {
      final screenshot = await _captureScreenshot();
      if (screenshot == null) return;

      // Get ApiService lazily
      final apiService = Get.find<ApiService>();

      await apiService.post(
        ApiEndpoints.sendScreenFrame,
        data: {
          'session_token': _currentSessionToken,
          'frame_data': base64Encode(screenshot),
          'frame_number': _frameCounter++,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      developer.log('Frame sent successfully: $_frameCounter', name: _tag);
    } catch (e) {
      developer.log('Failed to send frame', name: _tag, error: e, level: 900);
    }
  }

  /// Mulai streaming screenshot
  static Future<void> startStreaming() async {
    if (_isStreaming || _currentSessionToken == null) return;

    developer.log('Stream started', name: _tag);

    _isStreaming = true;
    _frameCounter = 0;

    // Ambil frame tiap 500ms
    _streamTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _sendFrame(),
    );
  }

  /// Stop streaming
  static void stopStreaming() {
    developer.log('Stream stopped', name: _tag);

    _isStreaming = false;
    _streamTimer?.cancel();
    _currentSessionToken = null;
  }

  /// Capture screenshot -> return Uint8List
  static Future<Uint8List?> _captureScreenshot() async {
    try {
      final captured = await ScreenCapture().captureEntireScreen();
      if (captured == null) return null;
      return captured.buffer;
    } catch (e) {
      developer.log(
        "Failed to capture screenshot",
        name: _tag,
        error: e,
        level: 900,
      );
      return null;
    }
  }
}
