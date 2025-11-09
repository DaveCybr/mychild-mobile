// screens/permissions/permission_screen.dart - FIXED
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;
import '../../core/constants/app_colors.dart';
import '../../controllers/permission_controller.dart';
import '../../services/local/local_storage_service.dart';
import '../../widgets/common/custom_button.dart';
import '../dashboard/dashboard_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  static const String _tag = 'PermissionScreen';

  late final PermissionController _controller;

  @override
  void initState() {
    super.initState();
    developer.log('Permission screen initialized', name: _tag);

    WidgetsBinding.instance.addObserver(this);
    _controller = Get.put(PermissionController(), permanent: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Get.delete<PermissionController>();
    developer.log('Permission screen disposed', name: _tag);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    developer.log('Permission screen lifecycle: $state', name: _tag);

    if (state == AppLifecycleState.resumed) {
      developer.log('App resumed, checking permissions...', name: _tag);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _controller.checkAllPermissions();
        }
      });
    }
  }

  // ✅ FIX: Prevent infinite loop with proper state management
  Future<void> _requestNextPermission() async {
    final index = _controller.currentPermissionIndex.value;

    developer.log('========================================', name: _tag);
    developer.log('Processing permission index: $index', name: _tag);

    // ✅ Check if all permissions are granted first
    if (_controller.areAllPermissionsGranted()) {
      developer.log('✅ All permissions granted!', name: _tag);
      await LocalStorageService.setPermissionCompleted(true);

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Get.offAll(() => const DashboardScreen());
      }
      return;
    }

    // ✅ Check bounds
    if (index >= _controller.permissionTitles.length) {
      developer.log('Index out of bounds, checking completion', name: _tag);

      if (_controller.areAllPermissionsGranted()) {
        await LocalStorageService.setPermissionCompleted(true);
        if (mounted) {
          Get.offAll(() => const DashboardScreen());
        }
      }
      return;
    }

    bool granted = false;

    // ✅ FIX: Better permission flow
    switch (index) {
      case 0: // Location (Foreground)
        granted = await _controller.requestLocationPermission();
        if (granted) {
          // Immediately request background location
          _controller.currentPermissionIndex.value = 1;
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) _requestNextPermission();
        }
        break;

      case 1: // Background Location
        granted = await _controller.requestCameraPermission();
        break;

      case 2: // Camera
        granted = await _controller.requestNotificationPermission();
        break;

      case 3: // Notification
        granted = await _controller.requestStoragePermission();
        break;

      case 4: // Storage
        granted = await _controller.requestBatteryOptimization();
        break;

      case 5: // Battery
        granted = await _controller.requestScreenCapturePermission();
        break;

      case 6: // Screen Capture
        granted = await _controller.requestAccessibilityService();

      default:
        granted = true;
    }

    developer.log('Permission $index result: $granted', name: _tag);
    developer.log('========================================', name: _tag);

    if (granted) {
      // Move to next permission
      _controller.currentPermissionIndex.value = index + 1;
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        // Check if all granted
        if (_controller.areAllPermissionsGranted()) {
          await LocalStorageService.setPermissionCompleted(true);
          Get.offAll(() => const DashboardScreen());
        } else {
          // Continue to next permission
          _requestNextPermission();
        }
      }
    } else {
      // ✅ FIX: Don't infinite loop - let user manually retry
      developer.log('Permission denied, waiting for manual retry', name: _tag);

      Get.snackbar(
        'Permission Required',
        'Please grant this permission to continue',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Setup Permissions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              developer.log('Manual refresh triggered', name: _tag);
              _controller.checkAllPermissions();
            },
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Icon(Icons.security, size: 80, color: AppColors.primary),

              const SizedBox(height: 24),

              const Text(
                'Setup Permissions',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'We need some permissions to keep your family connected',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Permission list
              Expanded(
                child: GetBuilder<PermissionController>(
                  id: 'permission_list',
                  builder: (controller) {
                    return ListView.builder(
                      itemCount: controller.permissionTitles.length,
                      itemBuilder: (context, index) {
                        final isCurrentOrPast =
                            index <= controller.currentPermissionIndex.value;
                        final isGranted = _getPermissionStatus(index);

                        return _buildPermissionItem(
                          title: controller.permissionTitles[index],
                          description: controller.permissionDescriptions[index],
                          isActive:
                              index == controller.currentPermissionIndex.value,
                          isGranted: isGranted,
                          isPending: !isCurrentOrPast,
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Progress indicator
              GetBuilder<PermissionController>(
                id: 'progress',
                builder: (controller) {
                  final totalPermissions = controller.permissionTitles.length;
                  final grantedCount = _getGrantedCount();
                  final progress = grantedCount / totalPermissions;

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$grantedCount of $totalPermissions granted',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: AppColors.grey200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              Obx(
                () => CustomButton(
                  text: _controller.areAllPermissionsGranted()
                      ? 'Continue to Dashboard'
                      : 'Grant Permissions',
                  onPressed: () {
                    if (_controller.areAllPermissionsGranted()) {
                      LocalStorageService.setPermissionCompleted(true);
                      Get.offAll(() => const DashboardScreen());
                    } else {
                      _requestNextPermission();
                    }
                  },
                  icon: _controller.areAllPermissionsGranted()
                      ? const Icon(Icons.arrow_forward, color: Colors.white)
                      : const Icon(Icons.lock_open, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getGrantedCount() {
    int count = 0;
    if (_controller.locationGranted.value) count++;
    if (_controller.cameraGranted.value) count++;
    if (_controller.notificationGranted.value) count++;
    if (_controller.storageGranted.value) count++;
    if (_controller.batteryOptimizationDisabled.value) count++;
    if (_controller.screenCaptureGranted.value) count++;
    if (_controller.accessibilityGranted.value) count++;
    return count;
  }

  bool _getPermissionStatus(int index) {
    switch (index) {
      case 0:
        return _controller.locationGranted.value;
      case 1:
        return _controller.cameraGranted.value;
      case 2:
        return _controller.notificationGranted.value;
      case 3:
        return _controller.storageGranted.value;
      case 4:
        return _controller.batteryOptimizationDisabled.value;
      case 5:
        return _controller.screenCaptureGranted.value;
      case 6:
        return _controller.accessibilityGranted.value;
      default:
        return false;
    }
  }

  Widget _buildPermissionItem({
    required String title,
    required String description,
    required bool isActive,
    required bool isGranted,
    required bool isPending,
  }) {
    Color iconColor;
    IconData icon;
    Color borderColor;
    Color backgroundColor;

    if (isGranted) {
      iconColor = AppColors.success;
      icon = Icons.check_circle;
      borderColor = AppColors.success;
      backgroundColor = AppColors.success.withOpacity(0.05);
    } else if (isPending) {
      iconColor = AppColors.grey400;
      icon = Icons.radio_button_unchecked;
      borderColor = AppColors.border;
      backgroundColor = AppColors.white;
    } else if (isActive) {
      iconColor = AppColors.primary;
      icon = Icons.radio_button_checked;
      borderColor = AppColors.primary;
      backgroundColor = AppColors.primary.withOpacity(0.05);
    } else {
      iconColor = AppColors.warning;
      icon = Icons.error_outline;
      borderColor = AppColors.warning;
      backgroundColor = AppColors.warning.withOpacity(0.05);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isActive ? 2 : 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isPending
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isPending
                        ? AppColors.textDisabled
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
