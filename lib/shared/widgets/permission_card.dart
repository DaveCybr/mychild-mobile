
// shared/widgets/permission_card.dart
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

class PermissionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final PermissionStatus status;
  final VoidCallback? onTap;
  final bool isRequired;

  const PermissionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.status,
    this.onTap,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Row(
            children: [
              // Main icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: statusColor,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: AppConstants.defaultPadding),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.titleMedium,
                          ),
                        ),
                        if (isRequired)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Wajib',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: AppConstants.defaultPadding),
              
              // Status indicator
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  statusIcon,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case PermissionStatus.granted:
        return AppColors.success;
      case PermissionStatus.denied:
        return AppColors.error;
      case PermissionStatus.pending:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case PermissionStatus.granted:
        return Icons.check;
      case PermissionStatus.denied:
        return Icons.close;
      case PermissionStatus.pending:
        return Icons.access_time;
    }
  }
}

enum PermissionStatus {
  granted,
  denied,
  pending,
}