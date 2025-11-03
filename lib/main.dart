// lib/main.dart - FIXED VERSION
import 'package:couple_guard_child/core/bindings/initial_binding.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'core/themes/app_theme.dart';
import 'services/background/background_service_manager.dart';
import 'services/background/screen_capture_service.dart';
import 'services/fcm/fcm_service.dart';
import 'services/local/local_storage_service.dart';
import 'screens/splash/splash_screen.dart';
import 'dart:developer' as developer;

/// ✅ FIX: Simplified background handler tanpa dependency GetIt

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

    await ScreenCaptureService.initialize();
    // Step 3: Initialize local storage
    developer.log('Initializing local storage...', name: 'MAIN');
    await LocalStorageService.init();
    developer.log('✅ Local storage initialized', name: 'MAIN');

    // Step 4: Configure background service
    developer.log('Configuring background service...', name: 'MAIN');
    await BackgroundServiceManager.initializeService();
    developer.log('✅ Background service configured', name: 'MAIN');

    // Step 5: Initialize FCM (simplified)
    developer.log('Initializing FCM...', name: 'MAIN');
    await _initializeFCM();
    developer.log('✅ FCM initialized', name: 'MAIN');

    // Step 6: Lock orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Step 7: Set system UI overlay
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

/// ✅ Simplified FCM initialization tanpa FcmHandler.initialize()
Future<void> _initializeFCM() async {
  try {
    // Request permission
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    developer.log(
      'FCM Permission: ${settings.authorizationStatus}',
      name: 'FCM',
    );

    // Get token
    final token = await messaging.getToken();
    if (token != null) {
      developer.log('FCM Token: ${token.substring(0, 20)}...', name: 'FCM');
      await LocalStorageService.saveFcmToken(token);
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) {
      developer.log('FCM Token refreshed', name: 'FCM');
      LocalStorageService.saveFcmToken(newToken);
    });
  } catch (e) {
    developer.log('FCM init error', name: 'FCM', error: e);
  }
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
