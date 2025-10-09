// lib/main.dart - UPDATED WITH FCM INTEGRATION
import 'package:couple_guard_child/core/bindings/initial_binding.dart';
import 'package:couple_guard_child/services/fcm/fcm_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'core/themes/app_theme.dart';
import 'services/background/background_service_manager.dart';
import 'services/local/local_storage_service.dart';
import 'screens/splash/splash_screen.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  developer.log('========================================', name: 'MAIN');
  developer.log('🚀 APP STARTING', name: 'MAIN');

  try {
    // Step 1: Initialize Firebase
    developer.log('Initializing Firebase...', name: 'MAIN');
    await Firebase.initializeApp();
    developer.log('✅ Firebase initialized', name: 'MAIN');

    // Step 2: Register background FCM handler
    developer.log('Registering FCM background handler...', name: 'MAIN');
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    developer.log('✅ FCM background handler registered', name: 'MAIN');

    // Step 3: Initialize local storage
    developer.log('Initializing local storage...', name: 'MAIN');
    await LocalStorageService.init();
    developer.log('✅ Local storage initialized', name: 'MAIN');

    // Step 4: Configure background service (don't start yet)
    developer.log('Configuring background service...', name: 'MAIN');
    await BackgroundServiceManager.initializeService();
    developer.log('✅ Background service configured', name: 'MAIN');

    // Step 5: Initialize FCM (after local storage is ready)
    developer.log('Initializing FCM...', name: 'MAIN');
    await FcmHandler.initialize();
    developer.log('✅ FCM initialized', name: 'MAIN');

    // Step 6: Lock orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Step 7: Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    developer.log('✅ APP INITIALIZATION COMPLETE', name: 'MAIN');
    developer.log('========================================', name: 'MAIN');
  } catch (e, stackTrace) {
    developer.log(
      '❌ APP INITIALIZATION FAILED',
      name: 'MAIN',
      error: e,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  runApp(const ChildApp());
}

class ChildApp extends StatelessWidget {
  const ChildApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Family Safety',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: InitialBinding(),
      home: const SplashScreen(),
    );
  }
}
