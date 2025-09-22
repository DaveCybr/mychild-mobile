
// features/onboarding/presentation/widgets/onboarding_slide.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/onboarding_data.dart';

class OnboardingSlide extends StatelessWidget {
  final OnboardingData slide;

  const OnboardingSlide({
    super.key,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.largePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          
          // Illustration
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: _buildIllustration(),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Content
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Title
                Text(
                  slide.title,
                  style: AppTextStyles.displaySmall,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  slide.description,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    // Since we don't have actual SVG files, we'll use icons with background
    IconData iconData;
    Color iconColor;
    
    switch (slide.iconData) {
      case 'family_restroom':
        iconData = Icons.family_restroom;
        iconColor = AppColors.primary;
        break;
      case 'location_on':
        iconData = Icons.location_on;
        iconColor = AppColors.success;
        break;
      case 'security':
        iconData = Icons.security;
        iconColor = AppColors.warning;
        break;
      case 'rocket_launch':
        iconData = Icons.rocket_launch;
        iconColor = AppColors.info;
        break;
      default:
        iconData = Icons.info;
        iconColor = AppColors.primary;
    }

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            iconColor.withOpacity(0.1),
            iconColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Icon(
        iconData,
        size: 80,
        color: iconColor,
      ),
    );
  }
}
