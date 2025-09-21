// lib/screens/home/child_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:lottie/lottie.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/cute_button.dart';
import '../../widgets/status_card.dart';
import '../../widgets/emergency_button.dart';
import '../emergency/emergency_screen.dart';

class ChildDashboardScreen extends StatefulWidget {
  const ChildDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ChildDashboardScreen> createState() => _ChildDashboardScreenState();
}

class _ChildDashboardScreenState extends State<ChildDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);

    _loadDashboardData();
    _startServices();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    final appState = context.read<AppStateProvider>();
    final apiService = context.read<ApiService>();

    try {
      appState.setLoading(true);
      final dashboardResponse = await apiService.getChildDashboard();

      if (dashboardResponse.success) {
        appState.updateDashboard(dashboardResponse.dashboard);
      }
    } catch (e) {
      appState.setError('Failed to load dashboard data');
    } finally {
      appState.setLoading(false);
    }
  }

  Future<void> _startServices() async {
    final locationService = context.read<LocationService>();
    final notificationService = context.read<NotificationService>();
    final appState = context.read<AppStateProvider>();

    try {
      // Start location tracking
      final locationStarted = await locationService.startTracking();
      appState.updateLocationStatus(
        locationStarted ? LocationStatus.active : LocationStatus.stopped,
      );

      // Start notification listening
      await notificationService.startListening();
      appState.updateNotificationListening(true);
    } catch (e) {
      print('Failed to start services: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Consumer<AppStateProvider>(
          builder: (context, appState, child) {
            if (appState.isLoading && appState.dashboard == null) {
              return _buildLoadingScreen();
            }

            return RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with user info
                    _buildHeader(appState),
                    const SizedBox(height: 24),

                    // Emergency button (prominent)
                    _buildEmergencySection(),
                    const SizedBox(height: 24),

                    // Status cards
                    _buildStatusSection(appState),
                    const SizedBox(height: 24),

                    // Recent alerts
                    _buildRecentAlerts(appState),
                    const SizedBox(height: 24),

                    // Quick actions
                    _buildQuickActions(),

                    // Bottom spacing for floating emergency button
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      // Floating emergency button
      floatingActionButton: _buildFloatingEmergencyButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie.asset('assets/animations/loading_dashboard.json', height: 150),
          const SizedBox(height: 24),
          Text(
            'Loading your dashboard...',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppStateProvider appState) {
    final user = appState.currentUser;
    final family = appState.family;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  user?.name.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${user?.name.split(' ').first ?? 'User'}! 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      family != null
                          ? 'Connected to ${family.name}'
                          : 'Not connected to family',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Connection status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      appState.isHealthy
                          ? Colors.green[500]
                          : Colors.orange[500],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      appState.isHealthy ? 'Safe' : 'Issues',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            appState.appStatus,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.shield, color: Colors.red[600]),
              const SizedBox(width: 8),
              Text(
                'Emergency Help',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'If you ever feel unsafe or need help, press the emergency button. Your family will be notified immediately.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: EmergencyButton(
                  onPressed: () => _handleEmergencyPress(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(AppStateProvider appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safety Status',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatusCard(
                title: 'Location',
                status: _getLocationStatusText(appState.locationStatus),
                icon: Icons.location_on,
                isActive: appState.locationStatus == LocationStatus.active,
                onTap: () => _showLocationDetails(appState),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatusCard(
                title: 'Messages',
                status:
                    appState.notificationListening ? 'Monitoring' : 'Stopped',
                icon: Icons.message,
                isActive: appState.notificationListening,
                onTap: () => _showNotificationDetails(appState),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatusCard(
                title: 'Screen Share',
                status: appState.screenMirroring ? 'Active' : 'Ready',
                icon: Icons.screen_share,
                isActive: appState.screenMirroring,
                onTap: () => _showScreenDetails(appState),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatusCard(
                title: 'Family',
                status: appState.family != null ? 'Connected' : 'Not connected',
                icon: Icons.family_restroom,
                isActive: appState.family != null,
                onTap: () => _showFamilyDetails(appState),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentAlerts(AppStateProvider appState) {
    if (appState.recentAlerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Colors.green[500],
            ),
            const SizedBox(height: 12),
            Text(
              'No Recent Alerts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Everything looks good! Keep staying safe.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Alerts',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...appState.recentAlerts.take(3).map((alert) => _buildAlertCard(alert)),
      ],
    );
  }

  Widget _buildAlertCard(Alert alert) {
    final priorityColor = _getPriorityColor(alert.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.fromBorderSide(
          BorderSide(color: priorityColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getAlertIcon(alert.type), color: priorityColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Text(
                _formatTime(alert.triggeredAt),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          if (alert.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(alert.message, style: TextStyle(color: Colors.grey[600])),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Check In',
                'Send location to family',
                Icons.my_location,
                Colors.blue,
                _sendCheckIn,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Test Alert',
                'Send test notification',
                Icons.notifications_active,
                Colors.orange,
                _sendTestAlert,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    MaterialColor color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color[50],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color[600], size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingEmergencyButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: () => _handleEmergencyPress(),
            backgroundColor: Colors.red[600],
            icon: const Icon(Icons.emergency, color: Colors.white),
            label: const Text(
              'EMERGENCY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            elevation: 8,
          ),
        );
      },
    );
  }

  // Helper methods
  String _getLocationStatusText(LocationStatus status) {
    switch (status) {
      case LocationStatus.active:
        return 'Active';
      case LocationStatus.searching:
        return 'Searching...';
      case LocationStatus.stale:
        return 'Outdated';
      case LocationStatus.stopped:
        return 'Stopped';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'emergency':
        return Icons.emergency;
      case 'geofence':
        return Icons.location_off;
      case 'content':
        return Icons.warning;
      case 'battery':
        return Icons.battery_alert;
      default:
        return Icons.info;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // Action methods
  void _handleEmergencyPress() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmergencyScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _sendCheckIn() async {
    try {
      final locationService = context.read<LocationService>();
      final position = await locationService.getEmergencyLocation();

      if (position != null) {
        final apiService = context.read<ApiService>();
        await apiService.updateLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          batteryLevel: 100, // Get actual battery level
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in sent to family! 📍'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send check-in: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendTestAlert() async {
    try {
      final apiService = context.read<ApiService>();
      await apiService.triggerAlert(
        type: 'content',
        priority: 'low',
        title: 'Test Alert',
        message:
            'This is a test alert from ${context.read<AppStateProvider>().currentUser?.name}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test alert sent! 🔔'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send test alert: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLocationDetails(AppStateProvider appState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Location Sharing',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your location is shared with your family every 30 minutes or when you move significantly. This helps them know you\'re safe.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                CuteButton(
                  text: 'Send Location Now',
                  onPressed: _sendCheckIn,
                  isPrimary: true,
                  icon: Icons.my_location,
                ),
              ],
            ),
          ),
    );
  }

  void _showNotificationDetails(AppStateProvider appState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Message Monitoring',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Important notifications from your apps are shared with your family to help keep you safe online.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (!appState.notificationListening)
                  CuteButton(
                    text: 'Enable Monitoring',
                    onPressed: () async {
                      final notificationService =
                          context.read<NotificationService>();
                      await notificationService.startListening();
                      appState.updateNotificationListening(true);
                      Navigator.of(context).pop();
                    },
                    isPrimary: true,
                    icon: Icons.notifications_active,
                  ),
              ],
            ),
          ),
    );
  }

  void _showScreenDetails(AppStateProvider appState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Screen Sharing',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  appState.screenMirroring
                      ? 'Your screen is currently being shared with your family for support.'
                      : 'Screen sharing is ready. Your family can request to see your screen when you need help.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (appState.screenMirroring)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Screen sharing is active',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  void _showFamilyDetails(AppStateProvider appState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Family Connection',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (appState.family != null) ...[
                  Text(
                    'Connected to: ${appState.family!.name}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Family Code: ${appState.family!.familyCode}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Text(
                    'Not connected to any family. You need to join a family for safety features to work.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  CuteButton(
                    text: 'Connect to Family',
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/pairing');
                    },
                    isPrimary: true,
                    icon: Icons.family_restroom,
                  ),
                ],
              ],
            ),
          ),
    );
  }
}
