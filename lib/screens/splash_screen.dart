import 'package:couple_guard_child/screens/dashboard_screen.dart';
import 'package:couple_guard_child/screens/onboading_screen.dart';
import 'package:couple_guard_child/services/device_service.dart';
import 'package:couple_guard_child/services/fcm_service.dart';
import 'package:couple_guard_child/utils/native_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    _initAnimation();
    _checkAppStatus();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  Future<void> _checkAppStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    developer.log('========================================', name: _tag);
    developer.log('Starting app status check', name: _tag);

    try {
      // Device is paired, update FCM token
      developer.log('Device is paired, updating FCM token', name: _tag);

      final fcmToken = await FcmHandler.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        final deviceService = Get.find<DeviceService>();
        final success = await deviceService.updateFcmToken(fcmToken);

        if (success) {
          developer.log('✅ FCM token updated successfully', name: _tag);
        } else {
          developer.log('⚠️ Failed to update FCM token', name: _tag);
          await NativeBridgeHelper.clearDeviceDataFromNative();
        }
      }

      final isPaired = await NativeBridgeHelper.isPaired();
      developer.log('Device paired: $isPaired', name: _tag);

      if (!isPaired) {
        developer.log('Device not paired, going to onboarding', name: _tag);
        Get.offAll(() => const OnboardingScreen());
        return;
      }

      // Start tracking services
      final servicesStarted = await NativeBridgeHelper.startTrackingServices();
      if (servicesStarted) {
        developer.log('✅ Tracking services started', name: _tag);
      }

      developer.log('Going to dashboard', name: _tag);
      Get.offAll(() => const DashboardScreen());
    } catch (e, stackTrace) {
      developer.log(
        'Error during app initialization',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );

      // On error, go to onboarding
      Get.offAll(() => const OnboardingScreen());
    }

    developer.log('========================================', name: _tag);
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade600,
              Colors.blue.shade400,
              Colors.cyan.shade300,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 60,
                      color: Colors.blue,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Name
                  const Text(
                    'Pika',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tagline
                  const Text(
                    'Child Device',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Loading Indicator
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
