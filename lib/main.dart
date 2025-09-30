// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
      ],
      child: MaterialApp(
        title: 'Child App',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: Consumer<AuthService>(
          builder: (context, auth, _) {
            if (auth.isAuthenticated) return HomeScreen();
            return LoginScreen();
          },
        ),
      ),
    );
  }
}
