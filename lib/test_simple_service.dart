import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'test_device_service.dart';
import 'test_notif_listenet.dart';

class ServiceLogger {
  static File? _logFile;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _logFile = File("${dir.path}/service_log.txt");
    if (!(await _logFile!.exists())) {
      await _logFile!.create(recursive: true);
    }
  }

  static Future<void> log(String message) async {
    final timestamp =
        "[${DateTime.now().toIso8601String().substring(11, 19)}] ";
    final text = "$timestamp$message";
    print(text);
    if (_logFile != null) {
      await _logFile!.writeAsString("$text\n", mode: FileMode.append);
    }
  }
}

class BackgroundApiService {
  static const String baseUrl =
      'https://parentalcontrol.satelliteorbit.cloud/api';
  static String? _cachedDeviceId;

  static Future<String> _getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    _cachedDeviceId = await DeviceService.getDeviceId();
    return _cachedDeviceId!;
  }

  static Future<bool> sendLocation(double latitude, double longitude) async {
    try {
      final deviceId = await _getDeviceId();
      final url = Uri.parse('$baseUrl/device/locations');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'device_id': deviceId,
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(const Duration(seconds: 10));

      await ServiceLogger.log('Location API: ${response.statusCode}');
      return response.statusCode == 201;
    } catch (e) {
      await ServiceLogger.log('Location API error: $e');
      return false;
    }
  }
}

@pragma('vm:entry-point')
void onStartSimpleService(ServiceInstance service) async {
  await ServiceLogger.init();
  await ServiceLogger.log("========================================");
  await ServiceLogger.log("SIMPLE SERVICE STARTED");
  await ServiceLogger.log("========================================");

  DartPluginRegistrant.ensureInitialized();
  await ServiceLogger.log("Plugin registered");

  if (service is AndroidServiceInstance) {
    try {
      await service.setForegroundNotificationInfo(
        title: "Service Initializing...",
        content: "Preparing background process...",
      );

      service.setAsForegroundService();
      await ServiceLogger.log("Service promoted to foreground");

      await Future.delayed(const Duration(milliseconds: 400));

      await service.setForegroundNotificationInfo(
        title: "Monitoring Active",
        content: "Tracking location",
      );
    } catch (e) {
      await ServiceLogger.log("ERROR setting foreground: $e");
      service.stopSelf();
      return;
    }
  }

  // Location tracking
  bool locationEnabled = await Geolocator.isLocationServiceEnabled();
  if (!locationEnabled) {
    await ServiceLogger.log("Location service disabled");
  } else {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      await ServiceLogger.log("Location permission denied");
    } else {
      await ServiceLogger.log("Location permission granted");

      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) async {
        await ServiceLogger.log(
          "Location: ${position.latitude}, ${position.longitude}",
        );

        final success = await BackgroundApiService.sendLocation(
          position.latitude,
          position.longitude,
        );

        if (success) {
          await ServiceLogger.log("Location sent to server");
        }
      });
    }
  }

  int counter = 0;
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    counter++;
    if (service is AndroidServiceInstance) {
      try {
        if (await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: "Monitoring Active",
            content:
                "Updates: $counter - ${DateTime.now().toString().substring(11, 19)}",
          );
          await ServiceLogger.log("Heartbeat #$counter");
        } else {
          timer.cancel();
        }
      } catch (e) {
        timer.cancel();
      }
    }
  });

  service.on('stopService').listen((event) async {
    await ServiceLogger.log("Stop command received");
    service.stopSelf();
  });

  await ServiceLogger.log("Service fully initialized");
}

class SimpleServiceTest extends StatefulWidget {
  const SimpleServiceTest({super.key});

  @override
  State<SimpleServiceTest> createState() => _SimpleServiceTestState();
}

class _SimpleServiceTestState extends State<SimpleServiceTest> {
  String _status = 'Not initialized';
  final FlutterBackgroundService _service = FlutterBackgroundService();
  bool _isServiceConfigured = false;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _status = 'Checking permissions...');
    await ServiceLogger.init();
    await ServiceLogger.log("STEP 1: Checking permissions...");

    var locationStatus = await Permission.location.status;
    var notificationStatus = await Permission.notification.status;

    await ServiceLogger.log("Location: $locationStatus");
    await ServiceLogger.log("Notification: $notificationStatus");

    if (!locationStatus.isGranted) {
      locationStatus = await Permission.location.request();
    }

    if (!notificationStatus.isGranted) {
      notificationStatus = await Permission.notification.request();
    }

    if (locationStatus.isGranted && notificationStatus.isGranted) {
      await ServiceLogger.log("Permissions granted");
      _permissionsGranted = true;
      setState(() => _status = 'Permissions granted');
    } else {
      await ServiceLogger.log("Permissions denied");
      _permissionsGranted = false;
      setState(() => _status = 'Permissions required!');
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'This app needs:\n'
          '• Location permission\n'
          '• Notification permission\n\n'
          'Please grant these in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _configureService() async {
    if (_isServiceConfigured) {
      setState(() => _status = 'Already configured');
      return;
    }

    if (!_permissionsGranted) {
      setState(() => _status = 'Grant permissions first!');
      _showPermissionDialog();
      return;
    }

    setState(() => _status = 'Configuring service...');
    await ServiceLogger.log("STEP 2: Configuring service...");

    try {
      await _service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStartSimpleService,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: 'test_service_channel',
          initialNotificationTitle: 'Test Service',
          initialNotificationContent: 'Initializing...',
          foregroundServiceNotificationId: 888,
          foregroundServiceTypes: [AndroidForegroundType.location],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStartSimpleService,
        ),
      );

      _isServiceConfigured = true;
      setState(() => _status = 'Service configured');
      await ServiceLogger.log("Service configured successfully");
    } catch (e) {
      await ServiceLogger.log("Configure ERROR: $e");
      setState(() => _status = 'Config failed: $e');
    }
  }

  Future<void> _startService() async {
    await ServiceLogger.log("STEP 3: Starting service...");

    if (!_permissionsGranted) {
      setState(() => _status = 'Grant permissions first!');
      _showPermissionDialog();
      return;
    }

    if (!_isServiceConfigured) {
      await _configureService();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() => _status = 'Starting service...');

    try {
      final isAlreadyRunning = await _service.isRunning();
      if (isAlreadyRunning) {
        setState(() => _status = 'Already running');
        return;
      }

      _service.startService();
      await Future.delayed(const Duration(seconds: 2));

      final isRunning = await _service.isRunning();
      setState(() => _status = isRunning ? 'RUNNING' : 'Failed to start');
      await ServiceLogger.log("Service running: $isRunning");
    } catch (e) {
      await ServiceLogger.log("Start ERROR: $e");
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _stopService() async {
    await ServiceLogger.log("Stopping service...");
    try {
      _service.invoke('stopService');
      await Future.delayed(const Duration(milliseconds: 500));

      final isRunning = await _service.isRunning();
      setState(() => _status = isRunning ? 'Still running' : 'Stopped');
    } catch (e) {
      setState(() => _status = 'Stop error: $e');
    }
  }

  Future<void> _checkStatus() async {
    final isRunning = await _service.isRunning();

    String status = '';
    status += 'Permissions: ${_permissionsGranted ? "YES" : "NO"}\n';
    status += 'Configured: ${_isServiceConfigured ? "YES" : "NO"}\n';
    status += 'Running: ${isRunning ? "YES" : "NO"}';

    setState(() => _status = status);
  }

  Future<void> _checkNotificationAccess() async {
    final isGranted = await NotificationListenerService.isPermissionGranted();

    if (isGranted) {
      setState(() => _status = 'Notification Listener: Enabled');
      await ServiceLogger.log('Notification listener enabled');
    } else {
      setState(() => _status = 'Notification Listener: Disabled');
      await ServiceLogger.log('Notification listener disabled');

      if (mounted) {
        _showNotificationListenerDialog();
      }
    }
  }

  void _showNotificationListenerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Notification Access'),
        content: const Text(
          'To monitor notifications:\n\n'
          '1. Tap "Open Settings"\n'
          '2. Find "couple_guard_child"\n'
          '3. Toggle it ON\n'
          '4. Return to app',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              NotificationListenerService.openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _viewNotificationLog() async {
    final logs = await NotificationListenerService.readLog();
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notification Logs'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Text(
                logs.isEmpty ? 'No notifications yet' : logs,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await NotificationListenerService.clearLog();
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Service Test'),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 80, color: Colors.blue),
                const SizedBox(height: 20),
                const Text(
                  'Background Service Test',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildButton(
                  '1. CONFIGURE SERVICE',
                  Colors.orange,
                  _configureService,
                ),
                const SizedBox(height: 12),
                _buildButton('2. START SERVICE', Colors.green, _startService),
                const SizedBox(height: 12),
                _buildButton('3. CHECK STATUS', Colors.blue, _checkStatus),
                const SizedBox(height: 12),
                _buildButton('4. STOP SERVICE', Colors.red, _stopService),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Notification Listener',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildButton(
                  'CHECK NOTIF ACCESS',
                  Colors.purple,
                  _checkNotificationAccess,
                ),
                const SizedBox(height: 12),
                _buildButton(
                  'VIEW NOTIF LOGS',
                  Colors.indigo,
                  _viewNotificationLog,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 280,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
