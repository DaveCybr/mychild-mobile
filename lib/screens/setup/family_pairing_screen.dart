// lib/screens/setup/family_pairing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// import 'package:lottie/lottie.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/cute_button.dart';

class FamilyPairingScreen extends StatefulWidget {
  const FamilyPairingScreen({Key? key}) : super(key: key);

  @override
  State<FamilyPairingScreen> createState() => _FamilyPairingScreenState();
}

class _FamilyPairingScreenState extends State<FamilyPairingScreen>
    with TickerProviderStateMixin {
  final TextEditingController _familyCodeController = TextEditingController();
  final FocusNode _familyCodeFocus = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _familyCodeController.dispose();
    _familyCodeFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(),

                      // Main content
                      Expanded(child: _buildMainContent()),

                      // Family code input and join button
                      _buildFamilyCodeSection(),

                      // Skip option (for testing)
                      _buildSkipOption(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.blue),
            ),
            Expanded(
              child: Text(
                'Connect to Family',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 48), // Balance the back button
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 0.8, // Almost complete
          backgroundColor: Colors.blue[100],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animation
        // Lottie.asset(
        //   'assets/animations/family_connection.json',
        //   height: 200,
        //   repeat: true,
        // ),
        const SizedBox(height: 32),

        // Title and description
        Text(
          'Join Your Family! 👨‍👩‍👧‍👦',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        Text(
          'Ask your parent for the Family Code to connect your device to your family\'s safety network.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Instructions card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Text(
                    'How to get the Family Code:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInstructionStep('1', 'Ask your parent to open their app'),
              _buildInstructionStep('2', 'Go to Family Settings'),
              _buildInstructionStep('3', 'Share the 8-letter Family Code'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.blue[700])),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyCodeSection() {
    return Column(
      children: [
        // Family code input
        Container(
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
          child: TextField(
            controller: _familyCodeController,
            focusNode: _familyCodeFocus,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
            maxLength: 8,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              UpperCaseTextFormatter(),
            ],
            decoration: InputDecoration(
              hintText: 'ABC12345',
              hintStyle: TextStyle(color: Colors.grey[400], letterSpacing: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              counterText: '',
            ),
            onChanged: (value) {
              setState(() {
                _errorMessage = null;
              });
            },
            onSubmitted: (value) {
              if (value.length == 8) {
                _joinFamily();
              }
            },
          ),
        ),
        const SizedBox(height: 8),

        Text(
          'Enter the 8-character Family Code',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700], fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Join button
        CuteButton(
          text: 'Join Family',
          onPressed:
              _familyCodeController.text.length == 8 ? _joinFamily : () {},
          isPrimary: _familyCodeController.text.length == 8,
          isLoading: _isLoading,
          icon: Icons.family_restroom,
        ),
      ],
    );
  }

  Widget _buildSkipOption() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextButton(
        onPressed: () {
          // For development/testing - skip family pairing
          _showSkipDialog();
        },
        child: Text(
          'Skip for now (Testing)',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ),
    );
  }

  void _showSkipDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Skip Family Connection?'),
            content: const Text(
              'Skipping family connection means safety features won\'t work properly. This should only be used for testing.\n\nAre you sure you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacementNamed('/dashboard');
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Skip (Testing Only)'),
              ),
            ],
          ),
    );
  }

  Future<void> _joinFamily() async {
    if (_familyCodeController.text.length != 8) {
      setState(() {
        _errorMessage = 'Family code must be 8 characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final appState = context.read<AppStateProvider>();

      // Join family using API
      final response = await apiService.joinFamily(
        _familyCodeController.text.toUpperCase(),
      );

      if (response.success) {
        // Get family info
        final familyResponse = await apiService.getFamilyMembers();

        if (familyResponse.success && familyResponse.members.isNotEmpty) {
          // Find family info from members
          // final familyMember = familyResponse.members.first;

          // Update app state
          appState.setFamily(
            Family(
              id: 1, // This should come from the API response
              name: 'My Family', // This should come from the API response
              familyCode: _familyCodeController.text.toUpperCase(),
            ),
          );

          // Show success and navigate
          _showSuccessDialog();
        }
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Connection failed. Please check your internet and try again.';
      });
      print('Family join error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lottie.asset(
                //   'assets/animations/success_family.json',
                //   height: 120,
                //   repeat: false,
                // ),
                const SizedBox(height: 16),
                Text(
                  'Connected Successfully! 🎉',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You\'re now connected to your family\'s safety network. All safety features are ready!',
                  style: TextStyle(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CuteButton(
                  text: 'Let\'s Go!',
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed('/dashboard');
                  },
                  isPrimary: true,
                  icon: Icons.rocket_launch,
                ),
              ],
            ),
          ),
    );
  }
}

// Custom text formatter for uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
