// app/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (from design)
  static const Color primary = Color(0xFF0056F1); // Blue from design
  static const Color primaryDark = Color(0xFF0044CC);
  static const Color primaryLight = Color(0xFF3377FF);
  
  // Secondary Colors (from design)
  static const Color secondary = Color(0xFF000818); // Dark from design
  static const Color secondaryLight = Color(0xFF1A1A2E);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E8);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);
  
  // Permission Status Colors
  static const Color permissionGranted = success;
  static const Color permissionDenied = error;
  static const Color permissionPending = warning;
  
  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = white;
  static const Color surfaceVariant = Color(0xFFF8F9FA);
  
  // Border Colors
  static const Color border = Color(0xFFE1E5E9);
  static const Color borderLight = Color(0xFFF0F0F0);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = white;
}
