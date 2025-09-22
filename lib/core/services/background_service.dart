
// core/services/background_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:workmanager/workmanager.dart';

import '../storage/local_storage.dart';
import '../constants/app_constants.dart';
import '../constants/storage_keys.dart';

abstract class BackgroundService {
  static Future<void> initialize();
  static Future<bool> handleLocationUpdate();
  static Future<bool> handleStatusSync();
  static Future<void> startBackgroundTasks();
  static Future<void> stopBackgroundTasks();
}

class BackgroundServiceImpl implements BackgroundService {
  static Future<void> initialize() async {
    await FlutterBackgroundService().configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'family_tracking_channel',
        initialNotificationTitle: 'Famisafe Active',
        initialNotificationContent: 'Family protection is running',
        foregroundServiceNotificationId: 1001,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    if (Platform.isIOS) {
      // iOS background task handling
      Timer.periodic(const Duration(minutes: 1), (timer) async {
        await _performBackgroundTasks();
      });
    } else {
      // Android foreground service
      Timer.periodic(const Duration(seconds: 30), (timer) async {
        await _performBackgroundTasks();
      });
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return await _performBackgroundTasks();
  }

  static Future<bool> _performBackgroundTasks() async {
    try {
      // Perform location update
      await handleLocationUpdate();
      
      // Perform status sync
      await handleStatusSync();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> handleLocationUpdate() async {
    try {
      // This will be handled by LocationService
      // Just return true for now
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> handleStatusSync() async {
    try {
      // Sync app status, permissions, etc.
      // This will be implemented when we have the API client
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> startBackgroundTasks() async {
    // Register WorkManager tasks
    await Workmanager().registerPeriodicTask(
      AppConstants.locationUpdateTask,
      AppConstants.locationUpdateTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    
    await Workmanager().registerPeriodicTask(
      AppConstants.statusSyncTask,
      AppConstants.statusSyncTask,
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    
    // Start background service
    await FlutterBackgroundService().startService();
  }

  static Future<void> stopBackgroundTasks() async {
    await Workmanager().cancelAll();
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('stop');
    }
  }
}