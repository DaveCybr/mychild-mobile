// screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;
import '../../controllers/background_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../controllers/dashboard_controller.dart';
import '../../services/api/device_service.dart';
import '../../widgets/dashboard/connection_status_widget.dart';
import '../../widgets/dashboard/monitoring_status_widget.dart';
import '../../widgets/common/status_card.dart';
import '../onboarding/onboarding_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  static const String _tag = 'DashboardScreen';

  final DashboardController _controller = Get.put(DashboardController());
  late final BackgroundController _bgController;
  static const platform = MethodChannel('screen_capture_permission_channel');

  @override
  void initState() {
    super.initState();
    developer.log('Dashboard screen initialized', name: _tag);

    WidgetsBinding.instance.addObserver(this);

    // Initialize BackgroundController if not already registered
    if (!Get.isRegistered<BackgroundController>()) {
      developer.log('Registering BackgroundController', name: _tag);
      _bgController = Get.put(BackgroundController());
    } else {
      _bgController = Get.find<BackgroundController>();
    }

    // Start all services after dashboard is loaded
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && !_bgController.servicesRunning.value) {
        developer.log('Auto-starting background services...', name: _tag);
        _bgController.initializeAllServices();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    developer.log('Dashboard screen disposed', name: _tag);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    developer.log('App lifecycle state: $state', name: _tag);
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Minimize instead of closing
        developer.log('Back button pressed, minimizing', name: _tag);
        _controller.minimizeApp();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            // Menu
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'unpair') {
                  _showUnpairDialog();
                } else if (value == 'stop_services') {
                  _showStopServicesDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'unpair',
                  child: Row(
                    children: [
                      Icon(Icons.link_off, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Unpair Device',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        // backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Family Safety',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Obx(
                              () => Text(
                                'Code: ${_controller.familyCode.value}',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shield,
                            color: AppColors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ConnectionStatusWidget(controller: _controller),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Device Info Card
                      StatusCard(
                        title: 'Device Information',
                        icon: Icons.phone_android,
                        color: AppColors.primary,
                        children: [
                          Obx(
                            () => _buildInfoRow(
                              'Device ID',
                              _controller.deviceId.value.isNotEmpty
                                  ? '${_controller.deviceId.value.substring(0, 8)}...'
                                  : 'Loading...',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Obx(
                            () => _buildInfoRow(
                              'Battery Level',
                              '${_controller.batteryLevel.value}%',
                              trailing: Icon(
                                _getBatteryIcon(_controller.batteryLevel.value),
                                color: _getBatteryColor(
                                  _controller.batteryLevel.value,
                                ),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: () async {
                          await platform.invokeMethod(
                            'requestScreenCapturePermission',
                          );
                        },
                        child: Text('Enable Screen Capture (one-time)'),
                      ),
                      // Service Status Card
                      // Obx(
                      //   () => StatusCard(
                      //     title: 'Background Service',
                      //     icon: Icons.settings_system_daydream,
                      //     color: _bgController.servicesRunning.value
                      //         ? AppColors.success
                      //         : AppColors.error,
                      //     children: [
                      //       _buildInfoRow(
                      //         'Status',
                      //         _bgController.servicesRunning.value
                      //             ? 'Running'
                      //             : 'Stopped',
                      //         trailing: Icon(
                      //           _bgController.servicesRunning.value
                      //               ? Icons.check_circle
                      //               : Icons.cancel,
                      //           color: _bgController.servicesRunning.value
                      //               ? AppColors.success
                      //               : AppColors.error,
                      //           size: 20,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      const SizedBox(height: 16),

                      // Monitoring Status
                      const Text(
                        'Active Monitoring',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 16),

                      MonitoringStatusWidget(controller: _controller),

                      const SizedBox(height: 24),

                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.info,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Running in Background',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'This app continues monitoring even when minimized',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Floating minimize button
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            developer.log('Manual minimize button pressed', name: _tag);
            _controller.minimizeApp();
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.minimize, color: AppColors.white),
          label: const Text(
            'Minimize',
            style: TextStyle(color: AppColors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ],
    );
  }

  IconData _getBatteryIcon(int level) {
    if (level > 80) return Icons.battery_full;
    if (level > 50) return Icons.battery_5_bar;
    if (level > 20) return Icons.battery_3_bar;
    return Icons.battery_1_bar;
  }

  Color _getBatteryColor(int level) {
    if (level > 50) return AppColors.success;
    if (level > 20) return AppColors.warning;
    return AppColors.error;
  }

  void _showStopServicesDialog() {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Stop Services?'),
          ],
        ),
        content: const Text(
          'This will stop all monitoring services. Location tracking and notification mirroring will be paused.\n\nAre you sure?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Get.back();
              _bgController.stopAllServices();

              Get.snackbar(
                'Services Stopped',
                'All monitoring services have been stopped',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
            },
            child: const Text(
              'Stop Services',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnpairDialog() {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Unpair Device?'),
          ],
        ),
        content: const Text(
          'This will disconnect your device from the family. You will need to pair again with a family code.\n\nAre you sure?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Get.back(); // Close dialog

              // Show loading
              Get.dialog(
                const Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );

              // Stop services first
              _bgController.stopAllServices();
              await Future.delayed(const Duration(milliseconds: 500));

              // Unpair from server
              final deviceService = Get.find<DeviceService>();
              final success = await deviceService.unpairDevice();

              Get.back(); // Close loading

              if (success) {
                // Redirect to onboarding
                await Future.delayed(const Duration(milliseconds: 500));
                Get.offAll(() => const OnboardingScreen());
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to unpair device. Please try again.',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                );
              }
            },
            child: const Text('Unpair', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
