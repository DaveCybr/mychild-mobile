import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'providers/app_state_provider.dart';
import 'services/api_service.dart';
import 'services/background_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/screen_mirror_service.dart';
import 'screens/splash_screen.dart';
import 'screens/setup/permission_wizard_screen.dart';
import 'screens/setup/family_pairing_screen.dart';
import 'screens/home/child_dashboard_screen.dart';
import 'screens/emergency/emergency_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service
  await initializeBackgroundService();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const ParentalControlChildApp());
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // ✅ SIMPLIFIED: Remove custom notification channel - let plugin handle it
  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      autoStartOnBoot: true,
      // ✅ Use default notification channel
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'Safety Monitor',
      initialNotificationContent: 'Monitoring in background',
      foregroundServiceNotificationId: 888,
      // ✅ Specify only supported foreground service types
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // ✅ Simplified service initialization
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();

    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // ✅ Basic heartbeat without complex initialization
  Timer.periodic(const Duration(minutes: 2), (timer) async {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Safety Monitor Active",
        content: "Last check: ${DateTime.now().toString().substring(11, 16)}",
      );
    }
    print("Background service running: ${DateTime.now()}");
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

class ParentalControlChildApp extends StatelessWidget {
  const ParentalControlChildApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<LocationService>(
          create: (context) => LocationService(context.read<ApiService>()),
        ),
        Provider<NotificationService>(
          create: (context) => NotificationService(context.read<ApiService>()),
        ),
        Provider<ScreenMirrorService>(
          create: (context) => ScreenMirrorService(context.read<ApiService>()),
        ),
      ],
      child: MaterialApp(
        title: 'Safety Monitor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Roboto',
        ),
        home: const SplashScreen(),
        routes: {
          '/permissions': (context) => const PermissionWizardScreen(),
          '/pairing': (context) => const FamilyPairingScreen(),
          '/dashboard': (context) => const ChildDashboardScreen(),
          '/emergency': (context) => const EmergencyScreen(),
        },
      ),
    );
  }
}

class DeviceUtils {
  static Future<void> enableStealthMode() async {
    try {
      await _hideAppIcon();
    } catch (e) {
      print('Stealth mode setup failed: $e');
    }
  }

  static Future<void> _hideAppIcon() async {
    // Implementation depends on stealth requirements
  }

  static Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id;
  }
}
