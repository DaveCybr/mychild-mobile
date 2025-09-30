import 'dart:io';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../../core/constants/app_endpoints.dart';
import '../api/api_service.dart';
import '../local/local_storage_service.dart';

class CameraService {
  static List<CameraDescription>? _cameras;
  static CameraController? _controller;

  static Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      print('Failed to initialize cameras: $e');
    }
  }

  static Future<void> captureAndSend({bool useFrontCamera = true}) async {
    if (_cameras == null || _cameras!.isEmpty) {
      await initialize();
      if (_cameras == null || _cameras!.isEmpty) return;
    }

    try {
      // Select camera
      final camera = _cameras!.firstWhere(
        (camera) =>
            camera.lensDirection ==
            (useFrontCamera
                ? CameraLensDirection.front
                : CameraLensDirection.back),
        orElse: () => _cameras!.first,
      );

      // Initialize controller
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      // Take picture
      final XFile image = await _controller!.takePicture();

      // Send to API
      await _sendCameraCapture(image);

      // Dispose controller
      await _controller!.dispose();
      _controller = null;
    } catch (e) {
      print('Failed to capture and send: $e');
      _controller?.dispose();
      _controller = null;
    }
  }

  static Future<void> _sendCameraCapture(XFile image) async {
    try {
      final childId = await LocalStorageService.getChildId();
      if (childId == null) return;

      // Get ApiService lazily and initialize
      final apiService = Get.find<ApiService>();

      FormData formData = FormData.fromMap({
        'child_id': childId,
        'type': 'photo',
        'file': await MultipartFile.fromFile(
          image.path,
          filename: 'capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      await apiService.dio.post(ApiEndpoints.sendCameraCapture, data: formData);

      // Delete local file
      File(image.path).deleteSync();
    } catch (e) {
      print('Failed to send camera capture: $e');
    }
  }
}
