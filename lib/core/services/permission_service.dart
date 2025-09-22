// core/services/permission_service.dart
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'dart:io';

import '../constants/app_constants.dart';
import '../storage/local_storage.dart';
import '../constants/storage_keys.dart';

abstract class PermissionService {
  Future<bool> requestLocationPermission();
  Future<bool> requestNotificationPermission();
  Future<bool> requestBatteryOptimization();
  Future<bool> requestDeviceAdminPermission();
  Future<bool> requestCameraPermission();
  Future<bool> requestAudioPermission();
  Future<bool> requestStoragePermission();
  
  Future<PermissionStatusResult> checkAllPermissions();
  Future<bool> requestAllEssentialPermissions();
  Future<bool> requestAllEnhancedPermissions();
  Future<bool> openAppSettings();
  
  Stream<PermissionStatusResult> get permissionStatusStream;
}

class PermissionServiceImpl implements PermissionService {
  final LocalStorage _localStorage;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  static const MethodChannel _methodChannel = MethodChannel('com.famisafe.child/permissions');
  
  PermissionServiceImpl(this._localStorage);

  @override
  Future<bool> requestLocationPermission() async {
    try {
      // Check current permission status
      var status = await Permission.locationWhenInUse.status;
      
      if (status.isDenied || status.isLimited) {
        status = await Permission.locationWhenInUse.request();
      }
      
      if (status.isGranted) {
        // Request always location for background tracking
        var alwaysStatus = await Permission.locationAlways.status;
        if (alwaysStatus.isDenied || alwaysStatus.isLimited) {
          alwaysStatus = await Permission.locationAlways.request();
        }
        
        final isGranted = alwaysStatus.isGranted || status.isGranted;
        await _localStorage.setBool(StorageKeys.locationPermissionStatus, isGranted);
        return isGranted;
      }
      
      await _localStorage.setBool(StorageKeys.locationPermissionStatus, false);
      return false;
    } catch (e) {
      await _localStorage.setBool(StorageKeys.locationPermissionStatus, false);
      return false;
    }
  }

  @override
  Future<bool> requestNotificationPermission() async {
    try {
      var status = await Permission.notification.status;
      
      if (status.isDenied || status.isLimited) {
        status = await Permission.notification.request();
      }
      
      final isGranted = status.isGranted;
      await _localStorage.setBool(StorageKeys.notificationPermissionStatus, isGranted);
      return isGranted;
    } catch (e) {
      await _localStorage.setBool(StorageKeys.notificationPermissionStatus, false);
      return false;
    }
  }

  @override
  Future<bool> requestBatteryOptimization() async {
    try {
      if (Platform.isAndroid) {
        // Use method channel to request battery optimization exemption
        final result = await _methodChannel.invokeMethod<bool>('requestBatteryOptimization') ?? false;
        await _localStorage.setBool(StorageKeys.batteryPermissionStatus, result);
        return result;
      } else {
        // iOS doesn't have battery optimization settings
        await _localStorage.setBool(StorageKeys.batteryPermissionStatus, true);
        return true;
      }
    } catch (e) {
      await _localStorage.setBool(StorageKeys.batteryPermissionStatus, false);
      return false;
    }
  }

  @override
  Future<bool> requestDeviceAdminPermission() async {
    try {
      if (Platform.isAndroid) {
        final result = await _methodChannel.invokeMethod<bool>('requestDeviceAdmin') ?? false;
        await _localStorage.setBool(StorageKeys.deviceAdminPermissionStatus, result);
        return result;
      } else {
        // iOS doesn't have device admin concept
        await _localStorage.setBool(StorageKeys.deviceAdminPermissionStatus, true);
        return true;
      }
    } catch (e) {
      await _localStorage.setBool(StorageKeys.deviceAdminPermissionStatus, false);
      return false;
    }
  }

  @override
  Future<bool> requestCameraPermission() async {
    try {
      var status = await Permission.camera.status;
      
      if (status.isDenied || status.isLimited) {
        status = await Permission.camera.request();
      }
      
      final isGranted = status.isGranted;
      await _localStorage.setBool(StorageKeys.cameraPermissionStatus, isGranted);
      return isGranted;
    } catch (e) {
      await _localStorage.setBool(StorageKeys.cameraPermissionStatus, false);
      return false;
    }
  }

  @override
  Future<bool> requestAudioPermission() async {
    try {
      var status = await Permission.microphone.status;
      
      if (status.isDenied || status.isLimited) {
        status = await Permission.microphone.request();
      }
      
      final isGranted = status.isGranted;
      await _localStorage.setBool(StorageKeys.audioPermissionStatus, isGranted);
      return isGranted;
    } catch (e) {
      await _localStorage.setBool(StorageKeys.audioPermissionStatus, false);
      return false;
    }
  }

  @override
  Future<bool> requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        
        if (androidInfo.version.sdkInt >= 33) {
          // Android 13+ uses granular permissions
          var photoStatus = await Permission.photos.status;
          if (photoStatus.isDenied) {
            photoStatus = await Permission.photos.request();
          }
          
          final isGranted = photoStatus.isGranted;
          await _localStorage.setBool(StorageKeys.storagePermissionStatus, isGranted);
          return isGranted;
        } else {
          // Older Android versions
          var status = await Permission.storage.status;
          if (status.isDenied) {
            status = await Permission.storage.request();
          }
          
          final isGranted = status.isGranted;
          await _localStorage.setBool(StorageKeys.storagePermissionStatus, isGranted);
          return isGranted;
        }
      } else {
        // iOS
        var status = await Permission.photos.status;
        if (status.isDenied || status.isLimited) {
          status = await Permission.photos.request();
        }
        
        final isGranted = status.isGranted || status.isLimited;
        await _localStorage.setBool(StorageKeys.storagePermissionStatus, isGranted);
        return isGranted;
      }
    } catch (e) {
      await _localStorage.setBool(StorageKeys.storagePermissionStatus, false);
      return false;
    }
  }

  @override
  Future<PermissionStatusResult> checkAllPermissions() async {
    final permissions = <String, bool>{};
    
    // Essential permissions
    permissions[AppConstants.locationPermission] = 
        _localStorage.getBool(StorageKeys.locationPermissionStatus) ?? false;
    permissions[AppConstants.notificationPermission] = 
        _localStorage.getBool(StorageKeys.notificationPermissionStatus) ?? false;
    permissions[AppConstants.batteryPermission] = 
        _localStorage.getBool(StorageKeys.batteryPermissionStatus) ?? false;
    permissions[AppConstants.deviceAdminPermission] = 
        _localStorage.getBool(StorageKeys.deviceAdminPermissionStatus) ?? false;
    
    // Enhanced permissions
    permissions[AppConstants.cameraPermission] = 
        _localStorage.getBool(StorageKeys.cameraPermissionStatus) ?? false;
    permissions[AppConstants.audioPermission] = 
        _localStorage.getBool(StorageKeys.audioPermissionStatus) ?? false;
    permissions[AppConstants.storagePermission] = 
        _localStorage.getBool(StorageKeys.storagePermissionStatus) ?? false;
    
    final essentialPermissions = [
      AppConstants.locationPermission,
      AppConstants.notificationPermission,
      AppConstants.batteryPermission,
      AppConstants.deviceAdminPermission,
    ];
    
    final enhancedPermissions = [
      AppConstants.cameraPermission,
      AppConstants.audioPermission,
      AppConstants.storagePermission,
    ];
    
    final allEssentialGranted = essentialPermissions.every(
      (permission) => permissions[permission] == true,
    );
    
    final allEnhancedGranted = enhancedPermissions.every(
      (permission) => permissions[permission] == true,
    );
    
    return PermissionStatusResult(
      permissions: permissions,
      allEssentialGranted: allEssentialGranted,
      allEnhancedGranted: allEnhancedGranted,
      allPermissionsGranted: allEssentialGranted && allEnhancedGranted,
    );
  }

  @override
  Future<bool> requestAllEssentialPermissions() async {
    final results = await Future.wait([
      requestLocationPermission(),
      requestNotificationPermission(),
      requestBatteryOptimization(),
      requestDeviceAdminPermission(),
    ]);
    
    return results.every((result) => result);
  }

  @override
  Future<bool> requestAllEnhancedPermissions() async {
    final results = await Future.wait([
      requestCameraPermission(),
      requestAudioPermission(),
      requestStoragePermission(),
    ]);
    
    return results.every((result) => result);
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<PermissionStatusResult> get permissionStatusStream async* {
    while (true) {
      yield await checkAllPermissions();
      await Future.delayed(const Duration(seconds: 2));
    }
  }
}

class PermissionStatusResult {
  final Map<String, bool> permissions;
  final bool allEssentialGranted;
  final bool allEnhancedGranted;
  final bool allPermissionsGranted;
  
  const PermissionStatusResult({
    required this.permissions,
    required this.allEssentialGranted,
    required this.allEnhancedGranted,
    required this.allPermissionsGranted,
  });
  
  bool isPermissionGranted(String permission) {
    return permissions[permission] ?? false;
  }
  
  List<String> get deniedEssentialPermissions {
    const essentialPermissions = [
      AppConstants.locationPermission,
      AppConstants.notificationPermission,
      AppConstants.batteryPermission,
      AppConstants.deviceAdminPermission,
    ];
    
    return essentialPermissions
        .where((permission) => !isPermissionGranted(permission))
        .toList();
  }
  
  List<String> get deniedEnhancedPermissions {
    const enhancedPermissions = [
      AppConstants.cameraPermission,
      AppConstants.audioPermission,
      AppConstants.storagePermission,
    ];
    
    return enhancedPermissions
        .where((permission) => !isPermissionGranted(permission))
        .toList();
  }
  
  double get completionPercentage {
    final grantedCount = permissions.values.where((granted) => granted).length;
    return grantedCount / permissions.length;
  }
}