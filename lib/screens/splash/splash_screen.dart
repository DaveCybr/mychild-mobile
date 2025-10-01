// screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../services/local/local_storage_service.dart';
import '../../services/api/device_service.dart';
import '../onboarding/onboarding_screen.dart';
import '../permissions/permission_screen.dart';
import '../dashboard/dashboard_screen.dart';
import 'dart:developer' as developer;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _tag = 'SplashScreen';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
    _checkAppStatus();
  }

  Future<void> _checkAppStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    developer.log('Starting app status check', name: _tag);

    // Step 1: Cek local storage dulu
    // final isPairedLocal = await LocalStorageService.getIsPaired();

    // developer.log('Local pairing status: $isPairedLocal', name: _tag);

    // if (!isPairedLocal) {
    //   // Belum pernah pairing -> Onboarding
    //   developer.log('Not paired locally, go to onboarding', name: _tag);
    //   Get.offAll(() => const OnboardingScreen());
    //   return;
    // }

    // Step 2: Verify dengan server
    try {
      final deviceService = Get.find<DeviceService>();
      final serverData = await deviceService.verifyPairing();

      if (serverData == null) {
        // Data local ada, tapi server tidak ada (mungkin di-unpair dari parent)
        developer.log(
          'Local says paired, but server says not paired. Clearing local data.',
          name: _tag,
          level: 900,
        );

        await LocalStorageService.clearPairing();

        Get.snackbar(
          'Device Unpaired',
          'This device has been unpaired. Please pair again.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );

        Get.offAll(() => const OnboardingScreen());
        return;
      }

      developer.log(
        'Server verification successful, device is paired',
        name: _tag,
      );

      // Step 3: Cek permission status
      final isPermissionCompleted =
          await LocalStorageService.isPermissionCompleted();

      developer.log('Permission completed: $isPermissionCompleted', name: _tag);

      if (!isPermissionCompleted) {
        // Sudah pairing tapi belum setup permission
        Get.offAll(() => const PermissionScreen());
        return;
      }

      // Semua OK -> Dashboard
      Get.offAll(() => const DashboardScreen());
    } catch (e) {
      developer.log(
        'Error during server verification',
        name: _tag,
        error: e,
        level: 1000,
      );

      // Kalau ada error network, tetap lanjut berdasarkan local data
      developer.log('Network error, using local data', name: _tag, level: 900);

      final isPermissionCompleted =
          await LocalStorageService.isPermissionCompleted();

      if (!isPermissionCompleted) {
        Get.offAll(() => const PermissionScreen());
      } else {
        Get.offAll(() => const DashboardScreen());
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Family Safety',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Keeping you connected',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Loading indicator
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white,
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
