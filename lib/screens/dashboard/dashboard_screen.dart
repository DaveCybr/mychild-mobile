// screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/dashboard/connection_status_widget.dart';
import '../../widgets/dashboard/monitoring_status_widget.dart';
import '../../widgets/common/status_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  final DashboardController _controller = Get.put(DashboardController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Show minimal UI notification
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Get.snackbar(
          'Setup Complete',
          'The app will continue running in the background',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.success.withOpacity(0.9),
          colorText: AppColors.white,
        );
      }
    });

    // Auto-minimize after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _controller.minimizeApp();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.checkConnectivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Minimize instead of closing
        if (GetPlatform.isAndroid) {
          SystemNavigator.pop();
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
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
                          _buildInfoRow(
                            'Device ID',
                            _controller.deviceId.value.isNotEmpty
                                ? '${_controller.deviceId.value.substring(0, 8)}...'
                                : 'Loading...',
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
                                    'App Running in Background',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'This app will continue monitoring in the background to keep you safe',
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
            _controller.minimizeApp();
            if (GetPlatform.isAndroid) {
              SystemNavigator.pop();
            }
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
}
