import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_screen_capture/flutter_screen_capture.dart';

import '../../core/constants/app_endpoints.dart';
import '../../core/constants/app_constants.dart';
import '../api/api_service.dart';
import '../local/local_storage_service.dart';

class ScreenMonitorService {
  static Timer? _checkTimer;
  static Timer? _streamTimer;
  static bool _isStreaming = false;
  static String? _currentSessionToken;
  static int _frameCounter = 0;

  /// Mulai monitoring
  static void startMonitoring() {
    _checkTimer?.cancel();

    _checkTimer = Timer.periodic(
      Duration(seconds: AppConstants.screenCheckInterval),
      (_) => _checkForActiveSession(),
    );

    // Initial check
    _checkForActiveSession();
  }

  /// Hentikan monitoring
  static void stopMonitoring() {
    _checkTimer?.cancel();
    stopStreaming();
  }

  /// Cek ke server apakah ada sesi aktif
  static Future<void> _checkForActiveSession() async {
    try {
      final childId = await LocalStorageService.getChildId();
      if (childId == null) return;

      final apiService = ApiService();
      await apiService.init();

      final response = await apiService.get(
        ApiEndpoints.checkActiveSession.replaceAll(':childId', childId),
      );

      final isBeingMonitored = response.data['is_being_monitored'] ?? false;
      final activeSession = response.data['active_session'];

      if (isBeingMonitored && !_isStreaming && activeSession != null) {
        _currentSessionToken = activeSession['session_token'];
        await startStreaming();
      } else if (!isBeingMonitored && _isStreaming) {
        stopStreaming();
      }
    } catch (e) {
      print('Failed to check active session: $e');
    }
  }

  /// Mulai streaming screenshot
  static Future<void> startStreaming() async {
    if (_isStreaming || _currentSessionToken == null) return;

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
    _isStreaming = false;
    _streamTimer?.cancel();
    _currentSessionToken = null;
  }

  /// Kirim frame screenshot ke server
  static Future<void> _sendFrame() async {
    if (!_isStreaming || _currentSessionToken == null) return;

    try {
      final screenshot = await _captureScreenshot();
      if (screenshot == null) return;

      final apiService = ApiService();
      await apiService.init();

      await apiService.post(
        ApiEndpoints.sendScreenFrame,
        data: {
          'session_token': _currentSessionToken,
          'frame_data': base64Encode(screenshot),
          'frame_number': _frameCounter++,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to send frame: $e');
    }
  }

  /// Capture screenshot -> return Uint8List
  static Future<Uint8List?> _captureScreenshot() async {
    try {
      final captured = await ScreenCapture().captureEntireScreen();
      if (captured == null) return null;
      return captured.buffer; // ambil data gambar dari object
    } catch (e) {
      print("Failed to capture screenshot: $e");
      return null;
    }
  }
}
