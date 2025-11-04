// screens/permissions/permission_screen.dart - COMPLETE FIX
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;
import '../../core/constants/app_colors.dart';
import '../../controllers/permission_controller.dart';
import '../../services/background/screen_capture_service.dart';
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

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Initialize controller
    _controller = Get.put(PermissionController(), permanent: false);

    // Check if already all granted
    // _checkIfAllGranted();
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

      // Re-check permissions when app resumes
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _controller.checkAllPermissions();
          // _checkIfAllGranted();
        }
      });
    }
  }

  Future<void> _checkScreenCapturePermission() async {
    try {
      final isSupported = await ScreenCaptureService.isSupported();

      developer.log('Screen capture supported: $isSupported', name: _tag);

      if (!isSupported) {
        developer.log('⚠️ Requesting screen capture permission...', name: _tag);
        final granted = await ScreenCaptureService.requestPermission();
        developer.log(
          'Screen capture permission granted: $granted',
          name: _tag,
        );
      }
    } catch (e) {
      developer.log(
        'Error checking screen capture permission',
        name: _tag,
        error: e,
      );
    }
  }

  Future<void> _checkIfAllGranted() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted && _controller.areAllPermissionsGranted()) {
      developer.log(
        '✅ All permissions granted, navigating to dashboard',
        name: _tag,
      );

      await LocalStorageService.setPermissionCompleted(true);

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Get.offAll(() => const DashboardScreen());
      }
    }
  }

  // lib/screens/permissions/permission_screen.dart

  Future<void> _requestNextPermission() async {
    final index = _controller.currentPermissionIndex.value;

    developer.log('========================================', name: _tag);
    developer.log('Processing permission index: $index', name: _tag);

    if (index >= _controller.permissionTitles.length) {
      // ✅ Semua permission granted
      developer.log('All permissions granted!', name: _tag);
      await LocalStorageService.setPermissionCompleted(true);

      if (mounted) {
        Get.offAll(() => const DashboardScreen());
      }
      return;
    }

    bool granted = false;

    switch (index) {
      case 0: // Location
        granted = await _controller.requestLocationPermission();
        break;
      case 1: // Camera
        granted = await _controller.requestCameraPermission();
        break;
      case 2: // Notification
        granted = await _controller.requestNotificationPermission();
        break;
      case 3: // Storage
        granted = await _controller.requestStoragePermission();
        break;
      case 4: // Battery
        granted = await _controller.requestBatteryOptimization();
        break;
      case 5: // Screen Capture - ✅ WAJIB
        granted = await _controller.requestScreenCapturePermission();
        break;
      default:
        granted = true;
    }

    developer.log('Permission $index result: $granted', name: _tag);
    developer.log('========================================', name: _tag);

    if (granted) {
      // ✅ Lanjut ke permission berikutnya
      _controller.currentPermissionIndex.value = index + 1;
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        if (_controller.areAllPermissionsGranted()) {
          // Semua granted, ke dashboard
          _checkIfAllGranted();
        } else {
          // Lanjut ke permission berikutnya
          _requestNextPermission();
        }
      }
    } else {
      // ❌ TIDAK GRANTED - RETRY permission yang sama
      developer.log(
        'Permission denied, retrying same permission...',
        name: _tag,
      );

      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        // ✅ RETRY permission yang sama (tidak increment index)
        _requestNextPermission();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Setup Permissions'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              developer.log('Manual refresh triggered', name: _tag);
              _controller.checkAllPermissions();
              _checkIfAllGranted();
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
                      itemCount: controller
                          .permissionTitles
                          .length, // ✅ Was: -1, now include all
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
                  final completedPermissions =
                      controller.currentPermissionIndex.value;

                  final progress = completedPermissions / totalPermissions;

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$completedPermissions of $totalPermissions required', // ✅ All required
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
                  text:
                      _controller
                          .areAllCriticalPermissionsGranted() // ✅ Critical only
                      ? 'Continue to Dashboard'
                      : 'Grant Permissions',
                  onPressed: () {
                    if (_controller.areAllCriticalPermissionsGranted()) {
                      _checkIfAllGranted();
                    } else {
                      _requestNextPermission();
                    }
                  },
                  icon: _controller.areAllCriticalPermissionsGranted()
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
        return _controller.screenCaptureGranted.value; // ✅ ADD
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
