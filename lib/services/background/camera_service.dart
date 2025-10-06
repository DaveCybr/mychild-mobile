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
  static bool _isCapturing = false; // Prevent concurrent captures

  static Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      print('Failed to initialize cameras: $e');
    }
  }

  static Future<void> captureAndSend({bool useFrontCamera = true}) async {
    // Prevent concurrent captures
    if (_isCapturing) {
      print('Camera capture already in progress');
      return;
    }

    _isCapturing = true;

    try {
      if (_cameras == null || _cameras!.isEmpty) {
        await initialize();
        if (_cameras == null || _cameras!.isEmpty) {
          print('No cameras available');
          return;
        }
      }

      // Dispose existing controller first
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final camera = _cameras!.firstWhere(
        (camera) =>
            camera.lensDirection ==
            (useFrontCamera
                ? CameraLensDirection.front
                : CameraLensDirection.back),
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      // Small delay to ensure camera is ready
      await Future.delayed(const Duration(milliseconds: 300));

      final XFile image = await _controller!.takePicture();

      await _sendCameraCapture(image);
    } catch (e) {
      print('Failed to capture: $e');
    } finally {
      // Always cleanup
      try {
        await _controller?.dispose();
        _controller = null;
      } catch (e) {
        print('Failed to dispose camera: $e');
      }
      _isCapturing = false;
    }
  }

  static Future<void> _sendCameraCapture(XFile image) async {
    File? imageFile;
    try {
      imageFile = File(image.path);

      final childId = await LocalStorageService.getChildId();
      if (childId == null) {
        print('Child ID not found');
        return;
      }

      final apiService = Get.find<ApiService>();

      FormData formData = FormData.fromMap({
        'child_id': childId,
        'type': 'photo',
        'file': await MultipartFile.fromFile(
          image.path,
          filename: 'capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await apiService.dio.post(
        ApiEndpoints.sendCameraCapture,
        data: formData,
      );

      if (response.statusCode == 200) {
        print('✓ Camera capture sent successfully');
      }
    } catch (e) {
      print('Failed to send camera capture: $e');
    } finally {
      // Always delete temp file
      try {
        if (imageFile != null && await imageFile.exists()) {
          await imageFile.delete();
        }
      } catch (e) {
        print('Failed to delete temp file: $e');
      }
    }
  }
}
