import 'dart:async';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
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

// Implementation class
class BackgroundServiceImpl implements BackgroundService {
  static Future<void> initialize() async {
    try {
      final service = FlutterBackgroundService();
      
      await service.configure(
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
      
      print('Background service initialized successfully');
    } catch (e) {
      print('Failed to initialize background service: $e');
      // Tidak throw error, biarkan app tetap berjalan
    }
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    print('Background service started');
    
    bool isServiceRunning = true;
    
    // Setup stop listener
    service.on('stop').listen((event) {
      print('Background service stop requested');
      isServiceRunning = false;
      service.stopSelf();
    });
    
    if (Platform.isIOS) {
      // iOS background task handling - lebih jarang karena iOS lebih restrictive
      Timer.periodic(const Duration(minutes: 5), (timer) async {
        if (isServiceRunning) {
          await _performBackgroundTasks();
        } else {
          timer.cancel();
        }
      });
    } else {
      // Android foreground service - bisa lebih sering
      Timer.periodic(const Duration(minutes: 1), (timer) async {
        if (isServiceRunning) {
          await _performBackgroundTasks();
        } else {
          timer.cancel();
        }
      });
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    print('iOS background task triggered');
    return await _performBackgroundTasks();
  }

  static Future<bool> _performBackgroundTasks() async {
    try {
      print('Performing background tasks...');
      
      // Perform location update
      bool locationSuccess = await handleLocationUpdate();
      print('Location update: $locationSuccess');
      
      // Perform status sync
      bool statusSuccess = await handleStatusSync();
      print('Status sync: $statusSuccess');
      
      return locationSuccess && statusSuccess;
    } catch (e) {
      print('Background task error: $e');
      return false;
    }
  }

  static Future<bool> handleLocationUpdate() async {
    try {
      print('Handling location update...');
      // TODO: Implement actual location update logic
      // For now, just simulate success
      await Future.delayed(Duration(seconds: 1));
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
      // For now, just simulate success
      await Future.delayed(Duration(seconds: 1));
      return true;
    } catch (e) {
      print('Status sync failed: $e');
      return false;
    }
  }

  static Future<void> startBackgroundTasks() async {
    try {
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
      final service = FlutterBackgroundService();
      bool isRunning = await service.isRunning();
      if (!isRunning) {
        await service.startService();
        print('Background service started');
      } else {
        print('Background service already running');
      }
    } catch (e) {
      print('Failed to start background tasks: $e');
    }
  }

  static Future<void> stopBackgroundTasks() async {
    try {
      await Workmanager().cancelAll();
      final service = FlutterBackgroundService();
      bool isRunning = await service.isRunning();
      if (isRunning) {
        service.invoke('stop');
        print('Background service stopped');
      } else {
        print('Background service not running');
      }
    } catch (e) {
      print('Failed to stop background tasks: $e');
    }
  }
}