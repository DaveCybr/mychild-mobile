// screens/permissions/permission_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../controllers/permission_controller.dart';
import '../../controllers/background_controller.dart';
import '../../widgets/common/custom_button.dart';
import '../dashboard/dashboard_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final PermissionController _controller = Get.put(PermissionController());

  @override
  void initState() {
    super.initState();
    // Initialize background controller
    Get.put(BackgroundController());
  }

  Future<void> _requestNextPermission() async {
    final index = _controller.currentPermissionIndex.value;

    if (index >= _controller.permissionTitles.length) {
      // All permissions handled, go to dashboard
      Get.offAll(() => const DashboardScreen());
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
        // case 5:
        //   granted = await _controller.requestAccessibilityPermission();
        break;
    }

    if (granted || index == 5) {
      // Move to next permission or finish
      _controller.currentPermissionIndex.value = index + 1;
      await Future.delayed(const Duration(milliseconds: 500));
      _requestNextPermission();
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

              // Title
              const Text(
                'Setup Permissions',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              // Description
              const Text(
                'We need some permissions to keep your family connected',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Permission list
              Expanded(
                child: Obx(
                  () => ListView.builder(
                    itemCount: _controller.permissionTitles.length,
                    itemBuilder: (context, index) {
                      final isCurrentOrPast =
                          index <= _controller.currentPermissionIndex.value;
                      final isGranted = _getPermissionStatus(index);

                      return _buildPermissionItem(
                        title: _controller.permissionTitles[index],
                        description: _controller.permissionDescriptions[index],
                        isActive:
                            index == _controller.currentPermissionIndex.value,
                        isGranted: isGranted,
                        isPending: !isCurrentOrPast,
                      );
                    },
                  ),
                ),
              ),

              // Progress indicator
              Obx(
                () => LinearProgressIndicator(
                  value:
                      (_controller.currentPermissionIndex.value + 1) /
                      _controller.permissionTitles.length,
                  backgroundColor: AppColors.grey200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action button
              CustomButton(
                text: 'Grant Permissions',
                onPressed: _requestNextPermission,
              ),

              const SizedBox(height: 16),

              // Skip button
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
                          onPressed: () {
                            Get.back();
                            Get.offAll(() => const DashboardScreen());
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
