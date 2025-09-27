// lib/screens/emergency/emergency_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// import 'package:vibration/vibration.dart';
// import 'package:lottie/lottie.dart';
import '../../services/api_service.dart';
import '../../services/emergency_service.dart';
import '../../services/location_service.dart';
import '../../widgets/cute_button.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  bool _isEmergencyActive = false;
  String? _selectedEmergencyType;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        title: const Text(
          'Emergency Help',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Emergency type selection
              if (!_isEmergencyActive) ...[
                _buildEmergencyTypeSelection(),
                const SizedBox(height: 24),
                _buildMessageInput(),
                const SizedBox(height: 32),
              ],

              // Main emergency button
              Expanded(
                child: _isEmergencyActive
                    ? _buildActiveEmergencyState()
                    : _buildEmergencyButton(),
              ),

              // Quick actions
              if (!_isEmergencyActive) _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What kind of help do you need?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.red[800],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildEmergencyTypeCard(
                'panic',
                'I\'m Scared',
                '😰',
                'Someone is bothering me or I feel unsafe',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEmergencyTypeCard(
                'help',
                'Need Help',
                '🆘',
                'I need assistance but it\'s not critical',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildEmergencyTypeCard(
                'medical',
                'Medical',
                '🏥',
                'I need medical attention',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEmergencyTypeCard(
                'accident',
                'Accident',
                '🚨',
                'There\'s been an accident',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmergencyTypeCard(
    String type,
    String title,
    String emoji,
    String description,
  ) {
    final isSelected = _selectedEmergencyType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEmergencyType = type;
        });
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red[100] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.red[400]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.red[700] : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.red[600] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional message (optional):',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: _messageController,
            maxLength: 200,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe what\'s happening...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyButton() {
    final canTrigger = _selectedEmergencyType != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big emergency button
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: Transform.scale(
                      scale: canTrigger ? _pulseAnimation.value : 1.0,
                      child: GestureDetector(
                        onTap: canTrigger ? _triggerEmergency : _shakeButton,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: canTrigger
                                  ? [
                                      Colors.red[400]!,
                                      Colors.red[600]!,
                                      Colors.red[800]!,
                                    ]
                                  : [
                                      Colors.grey[300]!,
                                      Colors.grey[400]!,
                                      Colors.grey[500]!,
                                    ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (canTrigger ? Colors.red : Colors.grey)
                                    .withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.emergency,
                                size: 48,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'EMERGENCY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              if (canTrigger) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'TAP TO SEND',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),

          if (!canTrigger)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please select what kind of help you need above',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Emergency alert will be sent to your family immediately',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your location, emergency type, and message will be shared with your family.',
                    style: TextStyle(color: Colors.red[600], fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveEmergencyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success animation
          // Lottie.asset(
          //   'assets/animations/emergency_sent.json',
          //   height: 200,
          //   repeat: false,
          // ),
          const SizedBox(height: 24),

          Text(
            'Emergency Alert Sent! 🚨',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Text(
            'Your family has been notified and can see your location. Help is on the way!',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Status information
          Container(
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
                _buildStatusItem(
                  Icons.location_on,
                  'Location shared',
                  'Your exact location has been sent',
                ),
                _buildStatusItem(
                  Icons.family_restroom,
                  'Family notified',
                  'All family members have been alerted',
                ),
                _buildStatusItem(
                  Icons.timer,
                  'Continuous tracking',
                  'Location updates every 30 seconds',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Additional actions
          Row(
            children: [
              Expanded(
                child: CuteButton(
                  text: 'Call Emergency',
                  onPressed: _callEmergencyNumber,
                  isPrimary: false,
                  icon: Icons.phone,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CuteButton(
                  text: 'Send Update',
                  onPressed: _sendLocationUpdate,
                  isPrimary: true,
                  icon: Icons.refresh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          CuteButton(
            text: 'I\'m Safe Now',
            onPressed: _markAsSafe,
            isPrimary: false,
            icon: Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.green[600], size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green[500], size: 20),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Call Parent',
                Icons.phone,
                Colors.blue,
                _callParent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                'Send Location',
                Icons.my_location,
                Colors.green,
                _sendLocationUpdate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                'False Alarm',
                Icons.cancel,
                Colors.grey,
                () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String text,
    IconData icon,
    MaterialColor color,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: color[600], size: 24),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                color: color[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Action methods
  void _shakeButton() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
    HapticFeedback.heavyImpact();
  }

  Future<void> _triggerEmergency() async {
    if (_selectedEmergencyType == null) return;

    // Show confirmation dialog for critical emergencies
    if (_selectedEmergencyType == 'panic' ||
        _selectedEmergencyType == 'medical') {
      final confirmed = await _showEmergencyConfirmation();
      if (!confirmed) return;
    }

    setState(() {
      _isEmergencyActive = true;
    });

    try {
      // Strong haptic feedback
      HapticFeedback.heavyImpact();
      // await Vibration.vibrate(duration: 1000);

      // Create emergency service
      final apiService = context.read<ApiService>();
      final locationService = context.read<LocationService>();
      final emergencyService = EmergencyService(apiService, locationService);

      // Trigger emergency based on type
      switch (_selectedEmergencyType!) {
        case 'panic':
          await emergencyService.triggerPanicEmergency(
            message: _messageController.text,
          );
          break;
        case 'help':
          await emergencyService.triggerHelpEmergency(
            message: _messageController.text,
          );
          break;
        case 'medical':
          await emergencyService.triggerMedicalEmergency(
            message: _messageController.text,
          );
          break;
        case 'accident':
          await emergencyService.triggerHelpEmergency(
            message: _messageController.text,
          );
          break;
      }

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Emergency alert sent successfully! 🚨'),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() {
        _isEmergencyActive = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send emergency alert: $e'),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<bool> _showEmergencyConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.red[600]),
                const SizedBox(width: 8),
                const Text('Confirm Emergency'),
              ],
            ),
            content: Text(
              'This will immediately alert your family that you need ${_selectedEmergencyType} help. Are you sure this is an emergency?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                ),
                child: const Text('Yes, Send Alert'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _callParent() async {
    try {
      final emergencyService = EmergencyService(
        context.read<ApiService>(),
        context.read<LocationService>(),
      );
      await emergencyService.callEmergencyContact();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to make call: $e')));
    }
  }

  Future<void> _callEmergencyNumber() async {
    try {
      final emergencyService = EmergencyService(
        context.read<ApiService>(),
        context.read<LocationService>(),
      );
      await emergencyService.callEmergencyContact();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to call emergency: $e')));
    }
  }

  Future<void> _sendLocationUpdate() async {
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
            content: Text('Location update sent! 📍'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send location: $e')));
    }
  }

  Future<void> _markAsSafe() async {
    try {
      final apiService = context.read<ApiService>();
      await apiService.triggerAlert(
        type: 'content',
        priority: 'medium',
        title: 'All Clear',
        message: 'I\'m safe now. Emergency is over.',
        data: {
          'emergency_resolved': true,
          'resolution_time': DateTime.now().toIso8601String(),
        },
      );

      setState(() {
        _isEmergencyActive = false;
        _selectedEmergencyType = null;
        _messageController.clear();
      });

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send safe status: $e')));
    }
  }
}

// lib/screens/splash_screen.dart
