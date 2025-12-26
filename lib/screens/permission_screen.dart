import 'package:couple_guard_child/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

import '../utils/native_bridge.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  static const String _tag = 'PermissionScreen';
  static const _platform = MethodChannel(
    'com.example.couple_guard_child/service',
  );

  // Permission status
  final RxBool _locationGranted = false.obs;
  final RxBool _backgroundLocationGranted = false.obs;
  final RxBool _notificationGranted = false.obs;
  final RxBool _notificationAccessGranted = false.obs;
  final RxBool _batteryOptimizationDisabled = false.obs;
  final RxBool _isCheckingPermissions = false.obs;

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  /// Check all required permissions
  Future<void> _checkAllPermissions() async {
    _isCheckingPermissions.value = true;
    developer.log('🔍 Checking all permissions...', name: _tag);

    try {
      // 1. Location permission
      final locationStatus = await Permission.location.status;
      _locationGranted.value = locationStatus.isGranted;
      developer.log('Location: ${locationStatus.name}', name: _tag);

      // 2. Background location (Android 10+)
      final bgLocationStatus = await Permission.locationAlways.status;
      _backgroundLocationGranted.value = bgLocationStatus.isGranted;
      developer.log(
        'Background Location: ${bgLocationStatus.name}',
        name: _tag,
      );

      // 3. Notification permission (Android 13+)
      final notificationStatus = await Permission.notification.status;
      _notificationGranted.value = notificationStatus.isGranted;
      developer.log('Notification: ${notificationStatus.name}', name: _tag);

      // 4. Notification access (NotificationListenerService)

      // 5. Battery optimization
      _batteryOptimizationDisabled.value = await _checkBatteryOptimization();
      developer.log(
        'Battery Optimization Disabled: ${_batteryOptimizationDisabled.value}',
        name: _tag,
      );
    } catch (e) {
      developer.log('❌ Error checking permissions', name: _tag, error: e);
    } finally {
      _isCheckingPermissions.value = false;
    }
  }

  /// Check if NotificationListenerService is enabled
  Future<bool> _checkNotificationAccess() async {
    try {
      // Call native method to check
      final result = await _platform.invokeMethod<bool>(
        'isNotificationAccessGranted',
      );
      return result ?? false;
    } catch (e) {
      developer.log('Error checking notification access', name: _tag, error: e);
      return false;
    }
  }

  /// Check if battery optimization is disabled
  Future<bool> _checkBatteryOptimization() async {
    try {
      final result = await _platform.invokeMethod<bool>(
        'isBatteryOptimizationDisabled',
      );
      return result ?? false;
    } catch (e) {
      developer.log(
        'Error checking battery optimization',
        name: _tag,
        error: e,
      );
      return false;
    }
  }

  /// Request location permissions (foreground + background)
  Future<void> _requestLocationPermission() async {
    developer.log('📍 Requesting location permissions...', name: _tag);

    try {
      // Step 1: Request foreground location
      final status = await Permission.location.request();
      _locationGranted.value = status.isGranted;

      if (!status.isGranted) {
        _showPermissionDialog(
          'Location Permission Required',
          'This app needs location access to track your device location for safety.',
          () => Permission.location.request(),
        );
        return;
      }

      developer.log('✅ Foreground location granted', name: _tag);

      // Step 2: Request background location (Android 10+)
      await Future.delayed(const Duration(milliseconds: 500));

      final bgStatus = await Permission.locationAlways.request();
      _backgroundLocationGranted.value = bgStatus.isGranted;

      if (!bgStatus.isGranted) {
        _showPermissionDialog(
          'Background Location Required',
          'Please select "Allow all the time" to enable continuous location tracking.',
          () => Permission.locationAlways.request(),
        );
      } else {
        developer.log('✅ Background location granted', name: _tag);
      }
    } catch (e) {
      developer.log(
        '❌ Error requesting location permission',
        name: _tag,
        error: e,
      );
    }
  }

  /// Request notification permission (Android 13+)
  Future<void> _requestNotificationPermission() async {
    developer.log('🔔 Requesting notification permission...', name: _tag);

    try {
      final status = await Permission.notification.request();
      _notificationGranted.value = status.isGranted;

      if (!status.isGranted) {
        _showPermissionDialog(
          'Notification Permission Required',
          'This app needs notification permission to show tracking status.',
          () => Permission.notification.request(),
        );
      } else {
        developer.log('✅ Notification permission granted', name: _tag);
      }
    } catch (e) {
      developer.log(
        '❌ Error requesting notification permission',
        name: _tag,
        error: e,
      );
    }
  }

  /// Open notification access settings
  Future<void> _openNotificationAccessSettings() async {
    developer.log('🔓 Opening notification access settings...', name: _tag);

    try {
      await _platform.invokeMethod('openNotificationAccess');
      _notificationAccessGranted.value = await _checkNotificationAccess();
      developer.log(
        'Notification Access: ${_notificationAccessGranted.value}',
        name: _tag,
      );
      // Show instruction dialog
      Get.dialog(
        AlertDialog(
          title: const Text('Enable Notification Access'),
          content: const Text(
            '1. Find "Couple Guard Child" in the list\n'
            '2. Toggle it ON\n'
            '3. Confirm by tapping OK\n'
            '4. Come back to this screen',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                // Recheck after 2 seconds
                Future.delayed(
                  const Duration(seconds: 2),
                  _checkAllPermissions,
                );
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      developer.log(
        '❌ Error opening notification access',
        name: _tag,
        error: e,
      );
    }
  }

  /// Open battery optimization settings
  Future<void> _openBatteryOptimizationSettings() async {
    developer.log('🔋 Opening battery optimization settings...', name: _tag);

    try {
      await _platform.invokeMethod('openBatteryOptimization');

      // Show instruction dialog
      Get.dialog(
        AlertDialog(
          title: const Text('Disable Battery Optimization'),
          content: const Text(
            '1. Select "All apps" from the dropdown\n'
            '2. Find "Couple Guard Child"\n'
            '3. Select "Don\'t optimize"\n'
            '4. Come back to this screen',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                Future.delayed(
                  const Duration(seconds: 2),
                  _checkAllPermissions,
                );
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      developer.log(
        '❌ Error opening battery optimization',
        name: _tag,
        error: e,
      );
    }
  }

  /// Open autostart settings (OEM-specific)
  /// Show permission explanation dialog
  void _showPermissionDialog(
    String title,
    String message,
    VoidCallback onRetry,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              onRetry();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Complete setup and start tracking
  Future<void> _completeSetup() async {
    developer.log('========================================', name: _tag);
    developer.log('🎯 Completing setup...', name: _tag);

    // Check if all critical permissions granted
    if (!_locationGranted.value || !_backgroundLocationGranted.value) {
      Get.snackbar(
        'Permission Required',
        'Location permission (Allow all the time) is required to continue.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (!_notificationAccessGranted.value) {
      Get.snackbar(
        'Permission Required',
        'Notification access is required to monitor notifications.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // Start tracking services
      developer.log('🚀 Starting tracking services...', name: _tag);
      final started = await NativeBridgeHelper.startTrackingServices();
      Get.offAll(() => const DashboardScreen());

      if (started) {
        developer.log('✅ Tracking services started', name: _tag);

        Get.snackbar(
          'Setup Complete!',
          'Device tracking is now active.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        developer.log('✅ Setup completed successfully', name: _tag);
      } else {
        developer.log('❌ Failed to start tracking services', name: _tag);
        Get.snackbar(
          'Error',
          'Failed to start tracking services. Please try again.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      developer.log('❌ Error completing setup', name: _tag, error: e);
    }

    developer.log('========================================', name: _tag);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Permissions'),
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        if (_isCheckingPermissions.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.security, size: 80, color: Colors.blue),
              const SizedBox(height: 16),

              const Text(
                'Required Permissions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              const Text(
                'This app needs these permissions to track location and monitor notifications for your safety.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Location Permission
              _buildPermissionCard(
                icon: Icons.location_on,
                title: 'Location Access',
                description: 'Track device location',
                isGranted:
                    _locationGranted.value && _backgroundLocationGranted.value,
                onTap: _requestLocationPermission,
                isCritical: true,
              ),

              const SizedBox(height: 12),

              // Notification Permission
              _buildPermissionCard(
                icon: Icons.notifications,
                title: 'Notification Permission',
                description: 'Show tracking status',
                isGranted: _notificationGranted.value,
                onTap: _requestNotificationPermission,
                isCritical: false,
              ),

              const SizedBox(height: 12),

              // Notification Access
              _buildPermissionCard(
                icon: Icons.message,
                title: 'Notification Access',
                description: 'Monitor app notifications',
                isGranted: _notificationAccessGranted.value,
                onTap: _openNotificationAccessSettings,
                isCritical: true,
              ),

              const SizedBox(height: 12),

              // Battery Optimization
              _buildPermissionCard(
                icon: Icons.battery_charging_full,
                title: 'Battery Optimization',
                description: 'Keep app running in background',
                isGranted: _batteryOptimizationDisabled.value,
                onTap: _openBatteryOptimizationSettings,
                isCritical: true,
              ),

              const SizedBox(height: 32),

              // Complete Setup Button
              ElevatedButton(
                onPressed: _completeSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Complete Setup'),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: _checkAllPermissions,
                child: const Text('Refresh Permissions'),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
    required bool isCritical,
    bool showCheckmark = true,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(
          icon,
          color: isGranted
              ? Colors.green
              : (isCritical ? Colors.red : Colors.orange),
          size: 32,
        ),
        title: Row(
          children: [
            Expanded(child: Text(title)),
            if (showCheckmark)
              Icon(
                isGranted ? Icons.check_circle : Icons.cancel,
                color: isGranted ? Colors.green : Colors.red,
                size: 20,
              ),
          ],
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: isGranted ? null : onTap,
      ),
    );
  }
}
