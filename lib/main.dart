import 'package:couple_guard_child/test_notif_listenet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'test_simple_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification listener
  await NotificationListenerService.init();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  print('');
  print('========================================');
  print('APP STARTING - CLEAN TEST');
  print('========================================');
  print('');

  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Service Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const SimpleServiceTest(),
    );
  }
}
