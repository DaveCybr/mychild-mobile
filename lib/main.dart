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
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize storage
  try {
    await Hive.initFlutter();
    await HiveBoxes.init();
    print('Hive initialized successfully');
  } catch (e) {
    print('Hive initialization failed: $e');
  }

  // Initialize dependency injection
  try {
    await di.init();
    print('Dependency injection initialized successfully');
  } catch (e) {
    print('Dependency injection failed: $e');
    rethrow;
  }

  // // Initialize WorkManager ONLY
  // try {
  //   await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  //   print('WorkManager initialized successfully');
  // } catch (e) {
  //   print('WorkManager initialization failed: $e');
  // }

  // Setup BLoC observer for debugging
  Bloc.observer = AppBlocObserver();

  // ❌ HAPUS INI - Jangan initialize background service di main()
  // try {
  //   await BackgroundServiceImpl.initialize();
  //   print('Background service initialized successfully');
  // } catch (e) {
  //   print('Background service initialization failed: $e');
  // }

  runApp(const FamisafeChildApp());
}

// Background task callback - HANYA untuk WorkManager
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     try {
//       print('Executing WorkManager task: $task');
//       switch (task) {
//         case 'locationUpdate':
//           return await BackgroundServiceImpl.handleLocationUpdate();
//         case 'statusSync':
//           return await BackgroundServiceImpl.handleStatusSync();
//         default:
//           print('Unknown task: $task');
//           return Future.value(true);
//       }
//     } catch (e) {
//       print('Background task failed: $e');
//       return Future.value(false);
//     }
//   });
// }
