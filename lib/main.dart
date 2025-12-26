import 'package:couple_guard_child/services/device_service.dart';
import 'package:couple_guard_child/services/fcm_service.dart';
import 'package:couple_guard_child/utils/local_storage.dart';
import 'package:couple_guard_child/utils/native_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as developer;

import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    // Initialize Firebase
    developer.log('🔥 Initializing Firebase...');
    await Firebase.initializeApp();
    developer.log('✅ Firebase initialized');

    // Initialize FCM
    developer.log('📱 Initializing FCM...');
    await FcmHandler.initialize();
    developer.log('✅ FCM initialized');

    // Initialize services with GetX
    developer.log('🔧 Initializing services...');
    Get.put(DeviceService());
    developer.log('✅ Services initialized');

    await _initializeDeviceId();
  } catch (e, stackTrace) {
    developer.log(
      '❌ Error during initialization',
      error: e,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  runApp(const MyApp());
}

Future<void> _initializeDeviceId() async {
  try {
    developer.log('📱 Checking device ID...', name: 'main');

    // Check if device ID already exists
    String? storedDeviceId = await LocalStorageService.getDeviceId();

    if (storedDeviceId != null && storedDeviceId.isNotEmpty) {
      developer.log(
        '✅ Device ID already exists: ${storedDeviceId.substring(0, 8)}...',
        name: 'main',
      );

      // Ensure it's synced to Native
      await NativeBridgeHelper.syncDeviceDataToNative(
        deviceId: storedDeviceId,
        isPaired: await LocalStorageService.getIsPaired(),
        familyCode: await LocalStorageService.getFamilyCode(),
        parentId: await LocalStorageService.getParentId(),
      );

      return;
    }

    // Generate new device ID from hardware
    developer.log('🔄 Generating new device ID...', name: 'main');
    final deviceService = Get.find<DeviceService>();
    final deviceId = await deviceService.getDeviceId();

    if (deviceId.isEmpty) {
      developer.log('❌ Failed to get device ID', name: 'main', level: 900);
      throw Exception('Failed to get device ID');
    }

    developer.log(
      '✅ Device ID generated: ${deviceId.substring(0, 8)}...',
      name: 'main',
    );

    // Save to SharedPreferences (both Flutter and Native keys)
    await LocalStorageService.saveDeviceId(deviceId);

    // Sync to Native
    await NativeBridgeHelper.syncDeviceDataToNative(
      deviceId: deviceId,
      isPaired: false, // Not paired yet
    );

    developer.log('✅ Device ID saved and synced to Native', name: 'main');
  } catch (e, stackTrace) {
    developer.log(
      '❌ Failed to initialize device ID',
      name: 'main',
      error: e,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Pika',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Poppins', // Optional: Add custom font
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade50,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          titleTextStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
