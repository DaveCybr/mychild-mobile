import 'dart:async';
import 'package:workmanager/workmanager.dart';
import '../constants/app_constants.dart';

// Abstract class untuk interface
abstract class BackgroundService {
  static Future<void> initialize() {
    throw UnimplementedError();
  }

  static Future<bool> handleLocationUpdate() {
    throw UnimplementedError();
  }

  static Future<bool> handleStatusSync() {
    throw UnimplementedError();
  }

  static Future<void> startBackgroundTasks() {
    throw UnimplementedError();
  }

  static Future<void> stopBackgroundTasks() {
    throw UnimplementedError();
  }
}

// Implementation class - HANYA menggunakan WorkManager
class BackgroundServiceImpl implements BackgroundService {
  // ❌ HAPUS FlutterBackgroundService - ini yang menyebabkan crash
  static Future<void> initialize() async {
    print('Background service ready (using WorkManager only)');
    // Tidak perlu initialize apa-apa, WorkManager sudah diinit di main()
  }

  static Future<bool> handleLocationUpdate() async {
    try {
      print('Handling location update...');

      // TODO: Implement actual location update logic
      // Ambil lokasi dan kirim ke server
      await Future.delayed(const Duration(seconds: 1));

      print('Location update completed');
      return true;
    } catch (e) {
      print('Location update failed: $e');
      return false;
    }
  }

  static Future<bool> handleStatusSync() async {
    try {
      print('Handling status sync...');

      // TODO: Implement actual status sync logic
      // Sync permission status, device info, etc
      await Future.delayed(const Duration(seconds: 1));

      print('Status sync completed');
      return true;
    } catch (e) {
      print('Status sync failed: $e');
      return false;
    }
  }

  static Future<void> startBackgroundTasks() async {
    try {
      print('Starting background tasks...');

      // Register WorkManager periodic tasks
      await Workmanager().registerPeriodicTask(
        AppConstants.locationUpdateTask,
        AppConstants.locationUpdateTask,
        frequency: const Duration(minutes: 15), // Minimal 15 menit
        constraints: Constraints(networkType: NetworkType.connected),
      );

      await Workmanager().registerPeriodicTask(
        AppConstants.statusSyncTask,
        AppConstants.statusSyncTask,
        frequency: const Duration(hours: 1),
        constraints: Constraints(networkType: NetworkType.connected),
      );

      print('Background tasks registered successfully');
    } catch (e) {
      print('Failed to start background tasks: $e');
    }
  }

  static Future<void> stopBackgroundTasks() async {
    try {
      print('Stopping background tasks...');
      await Workmanager().cancelAll();
      print('All background tasks cancelled');
    } catch (e) {
      print('Failed to stop background tasks: $e');
    }
  }
}
