// core/utils/device_info.dart
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfo {
  static late String deviceId;
  static late String deviceName;
  static late String deviceType;
  static late String appVersion;
  static late String osVersion;

  static Future<void> init() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    appVersion = packageInfo.version;

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
      deviceName = '${androidInfo.brand} ${androidInfo.model}';
      deviceType = 'android';
      osVersion = 'Android ${androidInfo.version.release}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? '';
      deviceName = iosInfo.name;
      deviceType = 'ios';
      osVersion = 'iOS ${iosInfo.systemVersion}';
    }
  }
}
