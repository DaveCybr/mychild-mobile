import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_screen_capture/flutter_screen_capture.dart';
import 'dart:developer' as developer;
import 'package:dio/dio.dart'; // ← TAMBAH INI

import '../../core/constants/app_endpoints.dart';
import '../../core/constants/app_constants.dart';
import '../local/local_storage_service.dart';

class ScreenMonitorService {
  static const String _tag = 'ScreenMonitorService';

  static Timer? _checkTimer;
  static Timer? _streamTimer;
  static bool _isStreaming = false;
  static String? _currentSessionToken;
  static int _frameCounter = 0;
  static late Dio _dio; // ← TAMBAH INI

  /// Mulai monitoring
  static void startMonitoring() {
    developer.log('Starting screen monitoring', name: _tag);

    _checkTimer?.cancel();

    _checkTimer = Timer.periodic(
      Duration(seconds: AppConstants.screenCheckInterval),
      (_) => _checkForActiveSession(),
    );

    Future.delayed(const Duration(seconds: 3), () {
      _checkForActiveSession();
    });
  }

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

      // Initialize Dio jika belum

      // Use Dio directly instead of ApiService
      try {
        final response = await _dio.get(
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
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
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
    } catch (e) {
      developer.log(
        'Unexpected error in _checkForActiveSession',
        name: _tag,
        error: e,
        level: 900,
      );
    }
  }

  static Future<void> _sendFrame() async {
    if (!_isStreaming || _currentSessionToken == null) return;

    try {
      final screenshot = await _captureScreenshot();
      if (screenshot == null) return;

      await _dio.post(
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

  static Future<void> startStreaming() async {
    if (_isStreaming || _currentSessionToken == null) return;

    developer.log('Stream started', name: _tag);

    _isStreaming = true;
    _frameCounter = 0;

    _streamTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _sendFrame(),
    );
  }

  static void stopStreaming() {
    developer.log('Stream stopped', name: _tag);

    _isStreaming = false;
    _streamTimer?.cancel();
    _currentSessionToken = null;
  }

  static Future<Uint8List?> _captureScreenshot() async {
    try {
      if (PlatformDispatcher.instance.onBeginFrame == null) {
        developer.log(
          "Skipped capture: running in background isolate",
          name: _tag,
          level: 800,
        );
        return null;
      }

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
