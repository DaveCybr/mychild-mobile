// services/background/service_watchdog.dart

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:workmanager/workmanager.dart';
import '../local/local_storage_service.dart';

class ServiceWatchdog {
  static const String WATCHDOG_TASK = 'service_watchdog';

  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);

    // Schedule periodic check every 15 minutes
    await Workmanager().registerPeriodicTask(
      WATCHDOG_TASK,
      WATCHDOG_TASK,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      if (task == WATCHDOG_TASK) {
        await _checkAndRestartService();
      }
      return Future.value(true);
    });
  }

  static Future<void> _checkAndRestartService() async {
    try {
      // Initialize storage
      await LocalStorageService.init();

      final isPaired = await LocalStorageService.getIsPaired();
      if (!isPaired) return;

      // Check if service is running
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();

      if (!isRunning) {
        print('⚠️ Service not running, restarting...');
        service.startService();
      }
    } catch (e) {
      print('Watchdog error: $e');
    }
  }
}
