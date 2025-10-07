// services/background/screen_monitor_service.dart - FIXED VERSION
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_screen_capture/flutter_screen_capture.dart';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';

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
  static Dio? _dio;

  /// ✅ FIX: Lazy initialization of Dio
  static Dio get dio {
    if (_dio == null) {
      developer.log('Initializing Dio for ScreenMonitorService', name: _tag);
      _dio = Dio(
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
      developer.log('✅ Dio initialized', name: _tag);
    }
    return _dio!;
  }

  /// Mulai monitoring
  static void startMonitoring() {
    developer.log('========================================', name: _tag);
    developer.log('STARTING SCREEN MONITORING', name: _tag);

    _checkTimer?.cancel();

    _checkTimer = Timer.periodic(
      Duration(seconds: AppConstants.screenCheckInterval),
      (_) => _checkForActiveSession(),
    );

    // Initial check after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _checkForActiveSession();
    });

    developer.log('Screen monitoring started', name: _tag);
    developer.log('========================================', name: _tag);
  }

  static void stopMonitoring() {
    developer.log('Stopping screen monitoring', name: _tag);
    _checkTimer?.cancel();
    stopStreaming();
    developer.log('✅ Screen monitoring stopped', name: _tag);
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

      developer.log('Checking for active session...', name: _tag);

      try {
        final response = await dio.get(
          ApiEndpoints.checkActiveSession.replaceAll(':childId', childId),
        );

        final isBeingMonitored = response.data['is_being_monitored'] ?? false;
        final activeSession = response.data['active_session'];

        developer.log(
          'Session check - Being monitored: $isBeingMonitored',
          name: _tag,
        );

        if (isBeingMonitored && !_isStreaming && activeSession != null) {
          _currentSessionToken = activeSession['session_token'];
          developer.log(
            '📺 Starting stream for session: $_currentSessionToken',
            name: _tag,
          );
          await startStreaming();
        } else if (!isBeingMonitored && _isStreaming) {
          developer.log('⏹️ Stopping stream - no active session', name: _tag);
          stopStreaming();
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          developer.log('No active session found (404)', name: _tag);

          // Stop streaming if currently active
          if (_isStreaming) {
            stopStreaming();
          }
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
      if (screenshot == null) {
        developer.log('Screenshot is null, skipping frame', name: _tag);
        return;
      }

      developer.log('Sending frame #$_frameCounter', name: _tag);

      await dio.post(
        ApiEndpoints.sendScreenFrame,
        data: {
          'session_token': _currentSessionToken,
          'frame_data': base64Encode(screenshot),
          'frame_number': _frameCounter++,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      developer.log('✅ Frame #$_frameCounter sent', name: _tag);
    } on DioException catch (e) {
      developer.log('Failed to send frame', name: _tag, error: e, level: 900);
    } catch (e) {
      developer.log('Unexpected error sending frame', name: _tag, error: e);
    }
  }

  static Future<void> startStreaming() async {
    if (_isStreaming || _currentSessionToken == null) {
      developer.log(
        'Cannot start streaming: already streaming or no session token',
        name: _tag,
      );
      return;
    }

    developer.log('📺 Stream started', name: _tag);

    _isStreaming = true;
    _frameCounter = 0;

    // ✅ Reduced frequency: 1 frame per second (instead of 500ms)
    _streamTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _sendFrame(),
    );
  }

  static void stopStreaming() {
    if (!_isStreaming) return;

    developer.log('⏹️ Stream stopped', name: _tag);

    _isStreaming = false;
    _streamTimer?.cancel();
    _streamTimer = null;
    _currentSessionToken = null;
    _frameCounter = 0;
  }

  static Future<Uint8List?> _captureScreenshot() async {
    try {
      // Check if running in background isolate
      if (PlatformDispatcher.instance.onBeginFrame == null) {
        developer.log(
          "Skipped: running in background isolate",
          name: _tag,
          level: 800,
        );
        return null;
      }

      final captured = await ScreenCapture().captureEntireScreen();
      if (captured == null) {
        developer.log('Screenshot capture returned null', name: _tag);
        return null;
      }

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

  /// Check if monitoring is active
  static bool get isMonitoring => _checkTimer != null && _checkTimer!.isActive;

  /// Check if streaming is active
  static bool get isStreaming => _isStreaming;
}
