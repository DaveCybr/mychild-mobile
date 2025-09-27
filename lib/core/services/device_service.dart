// core/services/device_service.dart
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../storage/local_storage.dart';
import '../constants/storage_keys.dart';

abstract class DeviceService {
  Future<DeviceInfo> getDeviceInfo();
  Future<String> getDeviceId();
  Future<AppInfo> getAppInfo();
  Future<bool> isDeviceRooted();
  Future<void> cacheDeviceInfo();
}

class DeviceServiceImpl implements DeviceService {
  final LocalStorage _localStorage;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  
  DeviceServiceImpl(this._localStorage);

  @override
  Future<DeviceInfo> getDeviceInfo() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      return DeviceInfo(
        platform: 'android',
        model: androidInfo.model,
        manufacturer: androidInfo.manufacturer,
        systemVersion: 'Android ${androidInfo.version.release}',
        systemName: 'Android',
        deviceId: androidInfo.id,
        brand: androidInfo.brand,
        hardware: androidInfo.hardware,
        isPhysicalDevice: androidInfo.isPhysicalDevice,
      );
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfoPlugin.iosInfo;
      return DeviceInfo(
        platform: 'ios',
        model: iosInfo.model,
        manufacturer: 'Apple',
        systemVersion: '${iosInfo.systemName} ${iosInfo.systemVersion}',
        systemName: iosInfo.systemName,
        deviceId: iosInfo.identifierForVendor ?? 'unknown',
        brand: 'Apple',
        hardware: iosInfo.utsname.machine,
        isPhysicalDevice: iosInfo.isPhysicalDevice,
      );
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }

  @override
  Future<String> getDeviceId() async {
    // Check if device ID is cached
    String? cachedDeviceId = _localStorage.getString(StorageKeys.deviceId);
    if (cachedDeviceId != null && cachedDeviceId.isNotEmpty) {
      return cachedDeviceId;
    }

    // Generate new device ID
    final deviceInfo = await getDeviceInfo();
    final deviceId = deviceInfo.deviceId;
    
    // Cache the device ID
    await _localStorage.setString(StorageKeys.deviceId, deviceId);
    
    return deviceId;
  }

  @override
  Future<AppInfo> getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    
    return AppInfo(
      appName: packageInfo.appName,
      packageName: packageInfo.packageName,
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      buildSignature: packageInfo.buildSignature,
    );
  }

  @override
  Future<bool> isDeviceRooted() async {
    try {
      if (Platform.isAndroid) {
        // Check for common root indicators on Android
        final rootPaths = [
          '/system/app/Superuser.apk',
          '/sbin/su',
          '/system/bin/su',
          '/system/xbin/su',
          '/data/local/xbin/su',
          '/data/local/bin/su',
          '/system/sd/xbin/su',
          '/system/bin/failsafe/su',
          '/data/local/su',
          '/su/bin/su',
        ];

        for (final path in rootPaths) {
          if (await File(path).exists()) {
            return true;
          }
        }

        // Check for root management apps
        final rootApps = [
          'com.noshufou.android.su',
          'com.noshufou.android.su.elite',
          'eu.chainfire.supersu',
          'com.koushikdutta.superuser',
          'com.thirdparty.superuser',
          'com.yellowes.su',
          'com.koushikdutta.rommanager',
          'com.koushikdutta.rommanager.license',
          'com.dimonvideo.luckypatcher',
          'com.chelpus.lackypatch',
          'com.ramdroid.appquarantine',
          'com.ramdroid.appquarantinepro',
        ];

        for (final app in rootApps) {
          try {
            final result = await Process.run('pm', ['list', 'packages', app]);
            if (result.stdout.toString().contains(app)) {
              return true;
            }
          } catch (e) {
            // Ignore errors
          }
        }

        return false;
      } else {
        // iOS jailbreak detection
        final jailbreakPaths = [
          '/Applications/Cydia.app',
          '/Library/MobileSubstrate/MobileSubstrate.dylib',
          '/bin/bash',
          '/usr/sbin/sshd',
          '/etc/apt',
          '/private/var/lib/apt/',
          '/private/var/lib/cydia',
          '/private/var/mobile/Library/SBSettings/Themes',
          '/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist',
          '/System/Library/LaunchDaemons/com.ikey.bbot.plist',
          '/Library/MobileSubstrate/DynamicLibraries/Veency.plist',
          '/private/var/lib/dpkg/info/mobilesubstrate.md5sums',
          '/Applications/FakeCarrier.app',
          '/Applications/Icy.app',
          '/Applications/IntelliScreen.app',
          '/Applications/MxTube.app',
          '/Applications/RockApp.app',
          '/Applications/SBSettings.app',
          '/Applications/WinterBoard.app',
          '/Applications/blackra1n.app',
        ];

        for (final path in jailbreakPaths) {
          if (await File(path).exists()) {
            return true;
          }
        }

        return false;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> cacheDeviceInfo() async {
    try {
      final deviceInfo = await getDeviceInfo();
      final appInfo = await getAppInfo();
      final isRooted = await isDeviceRooted();
      
      final deviceData = {
        'platform': deviceInfo.platform,
        'model': deviceInfo.model,
        'manufacturer': deviceInfo.manufacturer,
        'systemVersion': deviceInfo.systemVersion,
        'deviceId': deviceInfo.deviceId,
        'appVersion': appInfo.version,
        'buildNumber': appInfo.buildNumber,
        'isRooted': isRooted,
        'isPhysicalDevice': deviceInfo.isPhysicalDevice,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      
      await _localStorage.setString(StorageKeys.deviceInfo, deviceData.toString());
    } catch (e) {
      // Handle caching error
    }
  }
}

class DeviceInfo {
  final String platform;
  final String model;
  final String manufacturer;
  final String systemVersion;
  final String systemName;
  final String deviceId;
  final String brand;
  final String hardware;
  final bool isPhysicalDevice;

  const DeviceInfo({
    required this.platform,
    required this.model,
    required this.manufacturer,
    required this.systemVersion,
    required this.systemName,
    required this.deviceId,
    required this.brand,
    required this.hardware,
    required this.isPhysicalDevice,
  });

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'model': model,
      'manufacturer': manufacturer,
      'systemVersion': systemVersion,
      'systemName': systemName,
      'deviceId': deviceId,
      'brand': brand,
      'hardware': hardware,
      'isPhysicalDevice': isPhysicalDevice,
    };
  }
}

class AppInfo {
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;
  final String buildSignature;

  const AppInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    required this.buildSignature,
  });

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'packageName': packageName,
      'version': version,
      'buildNumber': buildNumber,
      'buildSignature': buildSignature,
    };
  }
}
