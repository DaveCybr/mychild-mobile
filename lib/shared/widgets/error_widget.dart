
// shared/widgets/error_widget.dart
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import 'common_button.dart';

class CommonErrorWidget extends StatelessWidget {
  final String? title;
  final String message;
  final String? buttonText;
  final VoidCallback? onRetry;
  final Widget? icon;

  const CommonErrorWidget({
    super.key,
    this.title,
    required this.message,
    this.buttonText,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon ??
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                style: AppTextStyles.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              CommonButton(
                text: buttonText ?? 'Coba Lagi',
                onPressed: onRetry,
                width: 140,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
