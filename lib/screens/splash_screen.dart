import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_state_provider.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));

    try {
      final apiService = context.read<ApiService>();
      final appState = context.read<AppStateProvider>();

      // Load saved authentication token
      await apiService.loadSavedToken();

      if (apiService.isConnected) {
        // Verify token is still valid
        final user = await apiService.getCurrentUser();
        appState.setUser(user);

        // Check setup completion status
        final prefs = await SharedPreferences.getInstance();
        final isSetupComplete = prefs.getBool('setup_complete') ?? false;
        final hasPermissions = prefs.getBool('permissions_granted') ?? false;

        appState.setSetupComplete(isSetupComplete);
        appState.setPermissionsGranted(hasPermissions);

        if (isSetupComplete && hasPermissions) {
          // Go to dashboard
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          // Continue setup
          Navigator.of(context).pushReplacementNamed('/permissions');
        }
      } else {
        // No valid token, show login
        _showLoginDialog();
      }
    } catch (e) {
      // Handle authentication error
      _showLoginDialog();
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Welcome!'),
            content: const Text(
              'This device needs to be set up by a parent or guardian. Please ask them to help you log in.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSimpleLogin();
                },
                child: const Text('Continue'),
              ),
            ],
          ),
    );
  }

  void _showSimpleLogin() {
    // For now, navigate to permissions. In real app, implement proper login
    Navigator.of(context).pushReplacementNamed('/permissions');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[600],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/animation
            // Lottie.asset(
            //   'assets/animations/app_logo.json',
            //   height: 200,
            //   repeat: true,
            // ),
            const SizedBox(height: 32),

            Text(
              'Safety Monitor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Keeping families connected and safe',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),

            // Loading indicator
            SizedBox(
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
    );
  }
}
