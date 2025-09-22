import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'app/app.dart';
import 'core/services/background_service.dart';
import 'core/storage/hive_boxes.dart';
import 'core/utils/bloc_observer.dart';
import 'app/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // System UI setup
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Initialize storage
  await Hive.initFlutter();
  await HiveBoxes.init();
  
  // Initialize dependency injection
  await di.init();
  
  // Initialize background service - PERBAIKAN DI SINI
  try {
    await BackgroundServiceImpl.initialize(); // Ganti dari BackgroundService.initialize()
  } catch (e) {
    print('Background service initialization failed: $e');
    // App tetap bisa berjalan meski background service gagal
  }
  
  // Initialize WorkManager for background tasks
  try {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  } catch (e) {
    print('WorkManager initialization failed: $e');
  }
  
  // Setup BLoC observer for debugging
  Bloc.observer = AppBlocObserver();
  
  runApp(const FamisafeChildApp());
}

// Background task callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case 'locationUpdate':
          return await BackgroundServiceImpl.handleLocationUpdate();
        case 'statusSync':
          return await BackgroundServiceImpl.handleStatusSync();
        default:
          return Future.value(true);
      }
    } catch (e) {
      print('Background task failed: $e');
      return Future.value(false);
    }
  });
}