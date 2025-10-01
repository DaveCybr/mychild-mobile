// screens/permissions/permission_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

class _PermissionScreenState extends State<PermissionScreen> {
  // Use Get.put with permanent: false to ensure proper lifecycle
  late final PermissionController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller properly
    _controller = Get.put(PermissionController(), permanent: false);
  }

  @override
  void dispose() {
    // Clean up controller when screen is disposed
    Get.delete<PermissionController>();
    super.dispose();
  }

  Future<void> _requestNextPermission() async {
    final index = _controller.currentPermissionIndex.value;

    if (index >= _controller.permissionTitles.length) {
      // PENTING: Simpan status permission selesai
      await LocalStorageService.setPermissionCompleted(true);

      // Semua permission selesai, ke dashboard
      if (mounted) {
        Get.offAll(() => const DashboardScreen());
      }
      return;
    }

    bool granted = false;

    switch (index) {
      case 0:
        granted = await _controller.requestLocationPermission();
        break;
      case 1:
        granted = await _controller.requestCameraPermission();
        break;
      case 2:
        granted = await _controller.requestNotificationPermission();
        break;
      case 3:
        granted = await _controller.requestStoragePermission();
        break;
      case 4:
        granted = await _controller.requestBatteryOptimization();
        break;
    }

    if (granted || index == 5) {
      _controller.currentPermissionIndex.value = index + 1;
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _requestNextPermission();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),

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

              const SizedBox(height: 48),

              // Use GetBuilder instead of Obx for better control
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

              // Progress indicator with GetBuilder
              GetBuilder<PermissionController>(
                id: 'progress',
                builder: (controller) {
                  return LinearProgressIndicator(
                    value:
                        (controller.currentPermissionIndex.value + 1) /
                        controller.permissionTitles.length,
                    backgroundColor: AppColors.grey200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              CustomButton(
                text: 'Grant Permissions',
                onPressed: _requestNextPermission,
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Get.dialog(
                    AlertDialog(
                      title: const Text('Skip Permissions?'),
                      content: const Text(
                        'Some features may not work properly without all permissions. Are you sure you want to skip?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            // PENTING: Tetap simpan status meskipun di-skip
                            await LocalStorageService.setPermissionCompleted(
                              true,
                            );
                            Get.back();
                            if (mounted) {
                              Get.offAll(() => const DashboardScreen());
                            }
                          },
                          child: const Text(
                            'Skip',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  'Skip for now',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
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

    if (isGranted) {
      iconColor = AppColors.success;
      icon = Icons.check_circle;
    } else if (isPending) {
      iconColor = AppColors.grey400;
      icon = Icons.radio_button_unchecked;
    } else if (isActive) {
      iconColor = AppColors.primary;
      icon = Icons.radio_button_checked;
    } else {
      iconColor = AppColors.error;
      icon = Icons.error_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withOpacity(0.05) : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.border,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
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
