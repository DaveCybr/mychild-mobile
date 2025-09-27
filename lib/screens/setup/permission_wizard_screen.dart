// lib/screens/setup/permission_wizard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:lottie/lottie.dart';
import '../../providers/app_state_provider.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/cute_button.dart';

class PermissionWizardScreen extends StatefulWidget {
  const PermissionWizardScreen({Key? key}) : super(key: key);

  @override
  State<PermissionWizardScreen> createState() => _PermissionWizardScreenState();
}

class _PermissionWizardScreenState extends State<PermissionWizardScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentPage = 0;

  // Permission states
  final Map<String, bool> _permissions = {
    'location': false,
    'notification': false,
    'screen': false,
    'battery': false,
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
    _checkExistingPermissions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingPermissions() async {
    final locationService = context.read<LocationService>();
    final notificationService = context.read<NotificationService>();

    setState(() {
      // Check permissions asynchronously
    });

    _permissions['location'] =
        await locationService.requestLocationPermission();
    _permissions['notification'] =
        await notificationService.hasNotificationPermission();
    _permissions['battery'] =
        await Permission.ignoreBatteryOptimizations.isGranted;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressBar(),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildLocationPermissionPage(),
                  _buildNotificationPermissionPage(),
                  _buildScreenPermissionPage(),
                  _buildBatteryOptimizationPage(),
                  _buildCompletionPage(),
                ],
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Setup Safety Features',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_currentPage + 1) / 6,
            backgroundColor: Colors.blue[100],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie.asset(
          //   'assets/animations/safety_welcome.json',
          //   height: 200,
          //   repeat: true,
          // ),
          const SizedBox(height: 32),
          Text(
            'Welcome to Safety Monitor! 👋',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'This app helps keep you safe by sharing your location and important notifications with your family.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We need a few permissions to keep you safe. Don\'t worry - we\'ll explain each one!',
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPermissionPage() {
    return PermissionPage(
      title: 'Location Sharing 📍',
      description:
          'This helps your family know where you are and alerts them if you need help.',
      benefits: [
        'Family can find you in emergencies',
        'Get help if you\'re in an unsafe area',
        'Share your location when you arrive safely',
      ],
      permission: 'location',
      isGranted: _permissions['location']!,
      onRequest: _requestLocationPermission,
      illustration: 'assets/animations/location_permission.json',
    );
  }

  Widget _buildNotificationPermissionPage() {
    return PermissionPage(
      title: 'Message Monitoring 💬',
      description:
          'This lets your family see important messages to help keep you safe online.',
      benefits: [
        'Protection from inappropriate messages',
        'Quick help if someone bothers you',
        'Share important notifications with family',
      ],
      permission: 'notification',
      isGranted: _permissions['notification']!,
      onRequest: _requestNotificationPermission,
      illustration: 'assets/animations/notification_permission.json',
    );
  }

  Widget _buildScreenPermissionPage() {
    return PermissionPage(
      title: 'Screen Sharing 📱',
      description:
          'This allows your family to see your screen when you need help or support.',
      benefits: [
        'Get help with apps and settings',
        'Family can assist with homework',
        'Quick support when you\'re confused',
      ],
      permission: 'screen',
      isGranted: _permissions['screen']!,
      onRequest: _requestScreenPermission,
      illustration: 'assets/animations/screen_permission.json',
      isOptional: true,
    );
  }

  Widget _buildBatteryOptimizationPage() {
    return PermissionPage(
      title: 'Battery Optimization ⚡',
      description:
          'This keeps the safety features working even when your phone tries to save battery.',
      benefits: [
        'Location sharing stays active',
        'Emergency features always work',
        'Consistent family connection',
      ],
      permission: 'battery',
      isGranted: _permissions['battery']!,
      onRequest: _requestBatteryOptimization,
      illustration: 'assets/animations/battery_permission.json',
    );
  }

  Widget _buildCompletionPage() {
    final allRequired =
        _permissions['location']! &&
        _permissions['notification']! &&
        _permissions['battery']!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie.asset(
          //   allRequired
          //       ? 'assets/animations/setup_complete.json'
          //       : 'assets/animations/setup_warning.json',
          //   height: 200,
          //   repeat: false,
          // ),
          const SizedBox(height: 32),
          Text(
            allRequired ? 'All Set! 🎉' : 'Almost Ready! ⚠️',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: allRequired ? Colors.green[700] : Colors.orange[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            allRequired
                ? 'All safety features are ready! Your family can now help keep you safe.'
                : 'Some features need permissions to work properly. You can change these later in settings.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildPermissionSummary(),
          const SizedBox(height: 32),
          CuteButton(
            text: allRequired ? 'Start Using App' : 'Continue Anyway',
            onPressed: _completeSetup,
            isPrimary: true,
          ),
          if (!allRequired) ...[
            const SizedBox(height: 12),
            CuteButton(
              text: 'Review Permissions',
              onPressed:
                  () => _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
              isPrimary: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionSummary() {
    return Container(
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
          _buildPermissionSummaryItem(
            'Location',
            _permissions['location']!,
            Icons.location_on,
          ),
          _buildPermissionSummaryItem(
            'Notifications',
            _permissions['notification']!,
            Icons.notifications,
          ),
          _buildPermissionSummaryItem(
            'Screen Share',
            _permissions['screen']!,
            Icons.screen_share,
          ),
          _buildPermissionSummaryItem(
            'Battery',
            _permissions['battery']!,
            Icons.battery_full,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSummaryItem(String name, bool granted, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: granted ? Colors.green[600] : Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: granted ? Colors.green[700] : Colors.grey[600],
                fontWeight: granted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green[600] : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: CuteButton(
                text: 'Back',
                onPressed:
                    () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                isPrimary: false,
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentPage == 0 ? 1 : 2,
            child: CuteButton(
              text: _getNextButtonText(),
              onPressed: _handleNextButton,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }

  String _getNextButtonText() {
    switch (_currentPage) {
      case 0:
        return 'Let\'s Start!';
      case 5:
        return 'Complete Setup';
      default:
        return 'Next';
    }
  }

  void _handleNextButton() {
    if (_currentPage == 5) {
      _completeSetup();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Permission request methods
  Future<void> _requestLocationPermission() async {
    final locationService = context.read<LocationService>();
    final granted = await locationService.requestLocationPermission();

    setState(() {
      _permissions['location'] = granted;
    });

    if (granted) {
      _showSuccessSnackBar('Location permission granted! 📍');
    } else {
      _showPermissionDeniedDialog('Location');
    }
  }

  Future<void> _requestNotificationPermission() async {
    final notificationService = context.read<NotificationService>();
    final granted = await notificationService.requestNotificationPermission();

    setState(() {
      _permissions['notification'] = granted;
    });

    if (granted) {
      _showSuccessSnackBar('Notification access granted! 💬');
    } else {
      _showPermissionDeniedDialog('Notification Access');
    }
  }

  Future<void> _requestScreenPermission() async {
    // Screen permission is requested when needed, not during setup
    setState(() {
      _permissions['screen'] = true; // Mark as "ready to request"
    });
    _showSuccessSnackBar('Screen sharing ready! 📱');
  }

  Future<void> _requestBatteryOptimization() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      final granted = status.isGranted;

      setState(() {
        _permissions['battery'] = granted;
      });

      if (granted) {
        _showSuccessSnackBar('Battery optimization disabled! ⚡');
      } else {
        _showPermissionDeniedDialog('Battery Optimization');
      }
    } catch (e) {
      print('Battery optimization request failed: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showPermissionDeniedDialog(String permissionName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('$permissionName Permission'),
            content: Text(
              'This permission is important for your safety. You can enable it later in Settings, but some features might not work properly.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('I Understand'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  void _completeSetup() {
    final appState = context.read<AppStateProvider>();

    // Check if we have minimum required permissions
    final hasMinimumPermissions =
        _permissions['location']! && _permissions['notification']!;

    appState.setPermissionsGranted(hasMinimumPermissions);
    appState.setSetupComplete(true);

    if (hasMinimumPermissions) {
      Navigator.of(context).pushReplacementNamed('/pairing');
    } else {
      // Show warning but allow to continue
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('⚠️ Important Permissions Missing'),
              content: const Text(
                'Some safety features won\'t work without proper permissions. Your family might not be able to help you in emergencies.\n\nYou can continue, but we recommend granting these permissions for your safety.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed('/pairing');
                  },
                  child: const Text('Continue Anyway'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _currentPage = 1;
                    });
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Review Permissions'),
                ),
              ],
            ),
      );
    }
  }
}

// lib/widgets/permission_card.dart
class PermissionPage extends StatelessWidget {
  final String title;
  final String description;
  final List<String> benefits;
  final String permission;
  final bool isGranted;
  final VoidCallback onRequest;
  final String illustration;
  final bool isOptional;

  const PermissionPage({
    Key? key,
    required this.title,
    required this.description,
    required this.benefits,
    required this.permission,
    required this.isGranted,
    required this.onRequest,
    required this.illustration,
    this.isOptional = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation
          // Lottie.asset(illustration, height: 160, repeat: true),
          const SizedBox(height: 24),

          // Title
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Benefits list
          Container(
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
                Row(
                  children: [
                    Icon(Icons.stars, color: Colors.amber[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Benefits:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...benefits.map(
                  (benefit) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 20,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            benefit,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Permission status and action
          if (isGranted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Permission Granted!',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                CuteButton(
                  text: 'Grant Permission',
                  onPressed: onRequest,
                  isPrimary: true,
                ),
                if (isOptional) ...[
                  const SizedBox(height: 8),
                  Text(
                    'This permission is optional',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

// lib/widgets/cute_button.dart
