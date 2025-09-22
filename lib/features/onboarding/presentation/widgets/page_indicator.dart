
// features/onboarding/presentation/widgets/page_indicator.dart
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class PageIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalPages;

  const PageIndicator({
    super.key,
    required this.currentIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => AnimatedContainer(
          duration: AppConstants.shortAnimationDuration,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: index == currentIndex ? 24 : 8,
          decoration: BoxDecoration(
            color: index == currentIndex
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
