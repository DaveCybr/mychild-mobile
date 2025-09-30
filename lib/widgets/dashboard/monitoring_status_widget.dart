// widgets/dashboard/monitoring_status_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../controllers/dashboard_controller.dart';

class MonitoringStatusWidget extends StatelessWidget {
  final DashboardController controller;

  const MonitoringStatusWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMonitoringItem(
          icon: Icons.location_on,
          title: 'Location Tracking',
          description: 'Sharing real-time location',
          isActive: controller.locationTracking,
          color: AppColors.success,
        ),
        const SizedBox(height: 12),
        _buildMonitoringItem(
          icon: Icons.notifications,
          title: 'Notification Mirroring',
          description: 'Syncing app notifications',
          isActive: controller.notificationMirroring,
          color: AppColors.info,
        ),
        const SizedBox(height: 12),
        _buildMonitoringItem(
          icon: Icons.screen_share,
          title: 'Screen Monitoring',
          description: 'Ready when parent requests',
          isActive: controller.screenMonitoring,
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildMonitoringItem({
    required IconData icon,
    required String title,
    required String description,
    required RxBool isActive,
    required Color color,
  }) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive.value ? color.withOpacity(0.05) : AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive.value ? color.withOpacity(0.3) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive.value
                    ? color.withOpacity(0.1)
                    : AppColors.grey200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isActive.value ? color : AppColors.grey500,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive.value
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive.value
                          ? AppColors.textSecondary
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isActive.value ? color : AppColors.grey400,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppColors.white, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}
