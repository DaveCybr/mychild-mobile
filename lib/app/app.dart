// app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:famisafe_child_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:famisafe_child_app/features/family/presentation/bloc/family_bloc.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../core/services/service_manager.dart';
import '../shared/repositories/auth_repository.dart';
import '../features/splash/presentation/bloc/splash_bloc.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import 'injection_container.dart' as di;

class FamisafeChildApp extends StatefulWidget {
  const FamisafeChildApp({super.key});

  @override
  State<FamisafeChildApp> createState() => _FamisafeChildAppState();
}

class _FamisafeChildAppState extends State<FamisafeChildApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize services after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAppServices();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground, check and restart services if needed
        ServiceManager.onAppResumed();
        break;
      case AppLifecycleState.paused:
        // App went to background
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        break;
      case AppLifecycleState.inactive:
        // App is inactive
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }

  Future<void> _initializeAppServices() async {
    try {
      // Only start services if user has already completed setup
      await ServiceManager.startServicesIfPermissionsGranted();
    } catch (e) {
      print('Failed to initialize app services: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SplashBloc()..add(SplashStarted())),
        BlocProvider(create: (_) => OnboardingBloc()..add(OnboardingStarted())),
        BlocProvider(
          create: (_) => AuthBloc(authRepository: di.sl<AuthRepository>()),
        ),
        BlocProvider(create: (_) => FamilyBloc()),
      ],
      child: MaterialApp.router(
        title: 'Famisafe Child',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.noScaling),
            child: child!,
          );
        },
      ),
    );
  }
}
