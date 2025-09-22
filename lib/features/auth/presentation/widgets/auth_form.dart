// features/auth/presentation/widgets/auth_form.dart
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class AuthForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final bool isLoading;

  const AuthForm({
    super.key,
    required this.formKey,
    required this.children,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius + 4),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IgnorePointer(
          ignoring: isLoading,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}