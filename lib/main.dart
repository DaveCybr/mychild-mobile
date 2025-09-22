// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'app/app.dart';
import 'core/storage/hive_boxes.dart';
// import 'core/services/background_service.dart';
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
  
  // Initialize background service
  // await BackgroundService.initialize();
  
  // Initialize WorkManager for background tasks
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  
  // Setup BLoC observer for debugging
  Bloc.observer = AppBlocObserver();
  
  runApp(const FamisafeChildApp());
}

// Background task callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    switch (task) {
      case 'locationUpdate':
        // return BackgroundService.handleLocationUpdate();
      case 'statusSync':
        // return BackgroundService.handleStatusSync();
      default:
        return Future.value(true);
    }
  });
}
