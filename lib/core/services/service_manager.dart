// core/services/service_manager.dart
import 'dart:io';
import 'package:flutter/services.dart';
import '../storage/local_storage.dart';
import '../constants/storage_keys.dart';
import 'background_service.dart';
import '../../app/injection_container.dart' as di;

class ServiceManager {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.famisafe.child/service_manager',
  );

  static LocalStorage get _localStorage => di.sl<LocalStorage>();

  /// Start all background services (call this after permissions are granted)
  static Future<bool> startAllServices() async {
    try {
      print('Starting all background services...');

      // 1. Start WorkManager background tasks
      await BackgroundServiceImpl.startBackgroundTasks();

      // 2. Start native location tracking (Android only)
      if (Platform.isAndroid) {
        try {
          final result = await _methodChannel.invokeMethod<bool>(
            'startLocationTracking',
          );

          if (result != true) {
            print('Failed to start native location tracking');
            // Don't return false here, WorkManager still works
          }
        } catch (e) {
          print('Error starting native location tracking: $e');
          // Continue with WorkManager only
        }
      }

      // 3. Mark services as started
      await _localStorage.setBool('services_started', true);

      print('Background services started successfully');
      return true;
    } catch (e) {
      print('Failed to start background services: $e');
      return false;
    }
  }

  /// Stop all background services
  static Future<bool> stopAllServices() async {
    try {
      print('Stopping all background services...');

      // 1. Stop WorkManager tasks
      await BackgroundServiceImpl.stopBackgroundTasks();

      // 2. Stop native location tracking
      if (Platform.isAndroid) {
        try {
          await _methodChannel.invokeMethod('stopLocationTracking');
        } catch (e) {
          print('Error stopping native location tracking: $e');
        }
      }

      // 3. Mark services as stopped
      await _localStorage.setBool('services_started', false);

      print('All background services stopped');
      return true;
    } catch (e) {
      print('Failed to stop background services: $e');
      return false;
    }
  }

  /// Check if services are running
  static Future<bool> areServicesRunning() async {
    try {
      return _localStorage.getBool('services_started') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Start services only if permissions are granted
  static Future<bool> startServicesIfPermissionsGranted() async {
    try {
      final permissionSetupCompleted =
          _localStorage.getBool(StorageKeys.permissionSetupCompleted) ?? false;

      if (!permissionSetupCompleted) {
        print('Permissions not granted yet, skipping service start');
        return false;
      }

      return await startAllServices();
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }

  /// Start services when app comes to foreground (for already setup users)
  static Future<void> onAppResumed() async {
    try {
      final permissionSetupCompleted =
          _localStorage.getBool(StorageKeys.permissionSetupCompleted) ?? false;

      if (permissionSetupCompleted) {
        final servicesRunning = await areServicesRunning();
        if (!servicesRunning) {
          print('App resumed, restarting services...');
          await startAllServices();
        }
      }
    } catch (e) {
      print('Error on app resumed: $e');
    }
  }
}
