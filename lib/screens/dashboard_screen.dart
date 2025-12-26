import 'package:couple_guard_child/screens/onboading_screen.dart';
import 'package:couple_guard_child/services/device_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;
import 'dart:async';
import '../utils/local_storage.dart';
import '../utils/native_bridge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const String _tag = 'DashboardScreen';

  final RxBool _isServiceRunning = false.obs;
  final RxString _deviceName = 'My Device'.obs;
  final RxString _familyCode = '------'.obs;
  final Rx<DateTime?> _lastSync = Rx<DateTime?>(null);

  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _checkServiceStatus();

    // Check status every 30 seconds
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkServiceStatus(),
    );
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceName = await LocalStorageService.getDeviceName();
      final familyCode = await LocalStorageService.getFamilyCode();
      final lastSync = await LocalStorageService.getLastSync();

      if (deviceName != null) _deviceName.value = deviceName;
      if (familyCode != null) _familyCode.value = familyCode;
      _lastSync.value = lastSync;

      developer.log('Device info loaded', name: _tag);
    } catch (e) {
      developer.log('Error loading device info', name: _tag, error: e);
    }
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
              NativeBridgeHelper.stopTrackingServices();
              await Future.delayed(const Duration(milliseconds: 500));

              // Unpair from server
              final deviceService = Get.find<DeviceService>();
              final success = await deviceService.unpairDevice();

              await LocalStorageService.clearAll();

              await NativeBridgeHelper.clearDeviceDataFromNative();

              await deviceService.updateDeviceStatus(false);

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

  Future<void> _checkServiceStatus() async {
    try {
      final isRunning = await NativeBridgeHelper.isTrackingServicesRunning();
      _isServiceRunning.value = isRunning;

      if (isRunning) {
        _lastSync.value = DateTime.now();
        await LocalStorageService.updateLastSync();
      }
    } catch (e) {
      developer.log('Error checking service status', name: _tag, error: e);
    }
  }

  Future<void> _restartService() async {
    try {
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        barrierDismissible: false,
      );

      final success = await NativeBridgeHelper.startTrackingServices();

      Get.back(); // Close loading dialog

      if (success) {
        Get.snackbar(
          'Success',
          'Monitoring service restarted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
        );
        await _checkServiceStatus();
      } else {
        Get.snackbar(
          'Error',
          'Failed to restart service',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
      }
    } catch (e) {
      Get.back();
      developer.log('Error restarting service', name: _tag, error: e);
    }
  }

  String _getTimeSinceSync() {
    if (_lastSync.value == null) return 'Never';

    final now = DateTime.now();
    final diff = now.difference(_lastSync.value!);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadDeviceInfo();
            await _checkServiceStatus();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.cyan.shade300,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pika',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Obx(
                              () => Text(
                                _deviceName.value,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Status Card
                  Obx(
                    () => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isServiceRunning.value
                              ? [Colors.green.shade400, Colors.green.shade600]
                              : [
                                  Colors.orange.shade400,
                                  Colors.orange.shade600,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isServiceRunning.value
                                        ? Colors.green
                                        : Colors.orange)
                                    .withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _isServiceRunning.value
                                ? Icons.check_circle
                                : Icons.info_outline,
                            size: 60,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isServiceRunning.value
                                ? 'Protected'
                                : 'Service Paused',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isServiceRunning.value
                                ? 'Monitoring active • Family connected'
                                : 'Tap restart to resume monitoring',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info Cards
                  _buildInfoCard(
                    icon: Icons.family_restroom,
                    title: 'Family Code',
                    value: _familyCode,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 12),

                  Obx(
                    () => _buildInfoCard(
                      icon: Icons.sync,
                      title: 'Last Sync',
                      value: RxString(_getTimeSinceSync()),
                      color: Colors.purple,
                    ),
                  ),

                  const SizedBox(height: 28),

                  ElevatedButton.icon(
                    onPressed: _showUnpairDialog,
                    icon: const Icon(Icons.link_off),
                    label: Text('Unpair Device'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Actions
                  Obx(
                    () => !_isServiceRunning.value
                        ? SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _restartService,
                              icon: const Icon(Icons.refresh),
                              label: const Text(
                                'Restart Monitoring',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // const SizedBox(height: ),

                  // Info Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This app keeps you safe by sharing your location with family. Keep it running in the background.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required RxString value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    value.value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
