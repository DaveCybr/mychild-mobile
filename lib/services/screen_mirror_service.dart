// lib/services/screen_mirror_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:screenshot/screenshot.dart';
import '../utils/app_config.dart';
import 'api_service.dart';

class ScreenMirrorService {
  final ApiService _apiService;
  static const MethodChannel _channel = MethodChannel('screen_capture');

  bool _isMirroring = false;
  String? _activeSessionToken;
  Timer? _captureTimer;
  int _frameNumber = 0;

  // Screenshot controller
  // final ScreenshotController _screenshotController = ScreenshotController();

  // Sensitive apps that should be blocked
  final Set<String> _sensitiveApps = {
    'com.android.vending', // Play Store
    'com.google.android.apps.authenticator2', // Google Authenticator
    'com.paypal.android.p2pmobile', // PayPal
    'com.android.settings', // Settings
    'com.android.packageinstaller', // Package Installer
  };

  ScreenMirrorService(this._apiService) {
    _setupMethodChannel();
    _startSessionMonitoring();
  }

  void _setupMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onScreenshotCaptured':
          await _handleScreenshotCaptured(call.arguments);
          break;
        case 'onSensitiveAppDetected':
          await _handleSensitiveAppDetected(call.arguments);
          break;
      }
    });
  }

  // Start monitoring for active screen mirroring sessions
  void _startSessionMonitoring() {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _checkActiveSession();
    });
  }

  // Check if there's an active screen mirroring session
  Future<void> _checkActiveSession() async {
    try {
      final response = await _apiService.getActiveScreenSession();

      if (response.isBeingMonitored && response.activeSession != null) {
        final sessionToken = response.activeSession!.sessionToken;

        if (!_isMirroring || _activeSessionToken != sessionToken) {
          await _startMirroring(sessionToken);
        }
      } else {
        if (_isMirroring) {
          await _stopMirroring();
        }
      }
    } catch (e) {
      print('Failed to check active session: $e');
    }
  }

  // Start screen mirroring
  Future<bool> _startMirroring(String sessionToken) async {
    if (_isMirroring) {
      await _stopMirroring();
    }

    // Request screen recording permission
    final hasPermission = await _requestScreenCapturePermission();
    if (!hasPermission) {
      print('Screen capture permission denied');
      return false;
    }

    _activeSessionToken = sessionToken;
    _isMirroring = true;
    _frameNumber = 0;

    // Start capturing screenshots at regular intervals
    _startPeriodicCapture();

    // Show subtle indicator that screen is being monitored
    await _showMirroringIndicator();

    print('Screen mirroring started with session: $sessionToken');
    return true;
  }

  // Stop screen mirroring
  Future<void> _stopMirroring() async {
    _isMirroring = false;
    _activeSessionToken = null;
    _captureTimer?.cancel();

    await _hideMirroringIndicator();

    try {
      await _channel.invokeMethod('stopScreenCapture');
    } catch (e) {
      print('Failed to stop screen capture: $e');
    }

    print('Screen mirroring stopped');
  }

  // Request screen capture permission
  Future<bool> _requestScreenCapturePermission() async {
    try {
      final result = await _channel.invokeMethod(
        'requestScreenCapturePermission',
      );
      return result == true;
    } catch (e) {
      print('Failed to request screen capture permission: $e');
      return false;
    }
  }

  // Start periodic screenshot capture
  void _startPeriodicCapture() {
    final interval = Duration(
      milliseconds: (1000 / AppConfig.maxFpsForStreaming).round(),
    );

    _captureTimer = Timer.periodic(interval, (timer) async {
      if (!_isMirroring) {
        timer.cancel();
        return;
      }

      await _captureAndSendScreen();
    });
  }

  // Capture and send screenshot
  Future<void> _captureAndSendScreen() async {
    try {
      // Check if current app is sensitive
      final currentApp = await _getCurrentForegroundApp();
      if (_sensitiveApps.contains(currentApp)) {
        await _sendBlockedScreenMessage();
        return;
      }

      // Capture screenshot using native method
      final screenshotBytes = await _captureNativeScreenshot();

      if (screenshotBytes != null) {
        // Compress and resize
        final compressedBytes = await _compressScreenshot(screenshotBytes);

        // Convert to base64
        final base64Screenshot = base64Encode(compressedBytes);

        // Send to server
        await _apiService.sendStreamFrame(
          sessionToken: _activeSessionToken!,
          frameData: base64Screenshot,
          frameNumber: _frameNumber++,
        );
      }
    } catch (e) {
      print('Failed to capture and send screenshot: $e');
    }
  }

  // Capture screenshot using native Android method
  Future<Uint8List?> _captureNativeScreenshot() async {
    try {
      final result = await _channel.invokeMethod('captureScreen');
      if (result != null) {
        return Uint8List.fromList(List<int>.from(result));
      }
    } catch (e) {
      print('Native screenshot failed: $e');
    }
    return null;
  }

  // Get current foreground app package name
  Future<String?> _getCurrentForegroundApp() async {
    try {
      return await _channel.invokeMethod('getCurrentApp');
    } catch (e) {
      return null;
    }
  }

  // Compress screenshot for bandwidth optimization
  Future<Uint8List> _compressScreenshot(Uint8List originalBytes) async {
    try {
      // Decode image
      final codec = await ui.instantiateImageCodec(originalBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Calculate new size maintaining aspect ratio
      final originalSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final targetSize = _calculateTargetSize(originalSize);

      // Create resized image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, originalSize.width, originalSize.height),
        Rect.fromLTWH(0, 0, targetSize.width, targetSize.height),
        Paint(),
      );

      final picture = recorder.endRecording();
      final resizedImage = await picture.toImage(
        targetSize.width.toInt(),
        targetSize.height.toInt(),
      );

      // Convert to JPEG with compression
      final byteData = await resizedImage.toByteData(
        format: ui.ImageByteFormat.png, // Use PNG for better quality
      );

      return byteData!.buffer.asUint8List();
    } catch (e) {
      print('Screenshot compression failed: $e');
      return originalBytes;
    }
  }

  // Calculate target size for compression
  Size _calculateTargetSize(Size originalSize) {
    final maxSize = AppConfig.maxScreenshotSize;

    if (originalSize.width <= maxSize.width &&
        originalSize.height <= maxSize.height) {
      return originalSize;
    }

    final widthRatio = maxSize.width / originalSize.width;
    final heightRatio = maxSize.height / originalSize.height;
    final scale = widthRatio < heightRatio ? widthRatio : heightRatio;

    return Size(originalSize.width * scale, originalSize.height * scale);
  }

  // Send blocked screen message when sensitive app is detected
  Future<void> _sendBlockedScreenMessage() async {
    try {
      // Send a placeholder image or message indicating screen is blocked
      final blockedMessage = base64Encode(
        utf8.encode('SCREEN_BLOCKED_SENSITIVE_APP'),
      );

      await _apiService.sendStreamFrame(
        sessionToken: _activeSessionToken!,
        frameData: blockedMessage,
        frameNumber: _frameNumber++,
      );
    } catch (e) {
      print('Failed to send blocked screen message: $e');
    }
  }

  // Handle screenshot captured from native side
  Future<void> _handleScreenshotCaptured(Map<dynamic, dynamic> args) async {
    // This would be called if using native screenshot capture
    final bytes = args['bytes'];
    if (bytes != null && _isMirroring) {
      final compressedBytes = await _compressScreenshot(
        Uint8List.fromList(List<int>.from(bytes)),
      );
      final base64Screenshot = base64Encode(compressedBytes);

      await _apiService.sendStreamFrame(
        sessionToken: _activeSessionToken!,
        frameData: base64Screenshot,
        frameNumber: _frameNumber++,
      );
    }
  }

  // Handle sensitive app detection
  Future<void> _handleSensitiveAppDetected(Map<dynamic, dynamic> args) async {
    await _sendBlockedScreenMessage();
  }

  // Show subtle mirroring indicator
  Future<void> _showMirroringIndicator() async {
    try {
      await _channel.invokeMethod('showMirroringIndicator');
    } catch (e) {
      print('Failed to show mirroring indicator: $e');
    }
  }

  // Hide mirroring indicator
  Future<void> _hideMirroringIndicator() async {
    try {
      await _channel.invokeMethod('hideMirroringIndicator');
    } catch (e) {
      print('Failed to hide mirroring indicator: $e');
    }
  }

  // Take manual screenshot (for emergency or on-demand)
  Future<String?> takeScreenshot() async {
    try {
      final screenshotBytes = await _captureNativeScreenshot();
      if (screenshotBytes != null) {
        final compressedBytes = await _compressScreenshot(screenshotBytes);
        return base64Encode(compressedBytes);
      }
    } catch (e) {
      print('Failed to take manual screenshot: $e');
    }
    return null;
  }

  // Check if screen mirroring is currently active
  bool get isMirroring => _isMirroring;

  // Get current session info
  String? get activeSessionToken => _activeSessionToken;

  void dispose() {
    _captureTimer?.cancel();
    stopMirroring();
  }

  Future<void> stopMirroring() async {
    await _stopMirroring();
  }
}

// lib/services/emergency_service.dart

// lib/providers/app_state_provider.dart
