// core/utils/permissions_handler.dart
import 'package:permission_handler/permission_handler.dart';

class PermissionsHandler {
  static Future<bool> checkAndRequestLocationPermission() async {
    final status = await Permission.locationAlways.status;

    if (status.isDenied) {
      final result = await Permission.locationAlways.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  static Future<bool> checkAndRequestCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  static Future<bool> checkAllPermissions() async {
    final permissions = [
      Permission.locationAlways,
      Permission.camera,
      Permission.storage,
      Permission.notification,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    return statuses.values.every((status) => status.isGranted);
  }
}
