// shared/widgets/common_button.dart
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;
  final ButtonSize size;
  final ButtonVariant variant;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;

  const CommonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.size = ButtonSize.large,
    this.variant = ButtonVariant.filled,
    this.backgroundColor,
    this.textColor,
    this.width,
  });

  const CommonButton.outlined({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.size = ButtonSize.large,
    this.backgroundColor,
    this.textColor,
    this.width,
  }) : variant = ButtonVariant.outlined;

  const CommonButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.size = ButtonSize.large,
    this.backgroundColor,
    this.textColor,
    this.width,
  }) : variant = ButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    final isButtonDisabled = isDisabled || isLoading || onPressed == null;
    final buttonHeight = _getButtonHeight();
    final textStyle = _getTextStyle();
    final buttonColors = _getButtonColors(context);

    Widget buttonChild = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == ButtonVariant.filled
                    ? AppColors.white
                    : AppColors.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(text, style: textStyle),
            ],
          );

    switch (variant) {
      case ButtonVariant.filled:
        return SizedBox(
          width: width ?? double.infinity,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: isButtonDisabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? buttonColors.background,
              foregroundColor: textColor ?? buttonColors.foreground,
              disabledBackgroundColor: AppColors.grey200,
              disabledForegroundColor: AppColors.grey400,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            child: buttonChild,
          ),
        );

      case ButtonVariant.outlined:
        return SizedBox(
          width: width ?? double.infinity,
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: isButtonDisabled ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor ?? buttonColors.foreground,
              disabledForegroundColor: AppColors.grey400,
              side: BorderSide(
                color: isButtonDisabled
                    ? AppColors.grey300
                    : backgroundColor ?? buttonColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            child: buttonChild,
          ),
        );

      case ButtonVariant.text:
        return SizedBox(
          width: width,
          height: buttonHeight,
          child: TextButton(
            onPressed: isButtonDisabled ? null : onPressed,
            style: TextButton.styleFrom(
              foregroundColor: textColor ?? buttonColors.foreground,
              disabledForegroundColor: AppColors.grey400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            child: buttonChild,
          ),
        );
    }
  }

  double _getButtonHeight() {
    switch (size) {
      case ButtonSize.small:
        return 40;
      case ButtonSize.medium:
        return 48;
      case ButtonSize.large:
        return AppConstants.buttonHeight;
    }
  }

  TextStyle _getTextStyle() {
    final baseStyle = switch (size) {
      ButtonSize.small => AppTextStyles.buttonSmall,
      ButtonSize.medium => AppTextStyles.buttonMedium,
      ButtonSize.large => AppTextStyles.buttonLarge,
    };

    return baseStyle.copyWith(
      color: textColor ?? _getButtonColors(null).foreground,
    );
  }

  ButtonColors _getButtonColors(BuildContext? context) {
    switch (variant) {
      case ButtonVariant.filled:
        return ButtonColors(
          background: AppColors.primary,
          foreground: AppColors.white,
          border: AppColors.primary,
        );
      case ButtonVariant.outlined:
        return ButtonColors(
          background: Colors.transparent,
          foreground: AppColors.primary,
          border: AppColors.primary,
        );
      case ButtonVariant.text:
        return ButtonColors(
          background: Colors.transparent,
          foreground: AppColors.primary,
          border: Colors.transparent,
        );
    }
  }
}

enum ButtonSize { small, medium, large }
enum ButtonVariant { filled, outlined, text }

class ButtonColors {
  final Color background;
  final Color foreground;
  final Color border;

  const ButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
  });
}
