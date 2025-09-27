// app/router/app_router.dart - Complete with all routes
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/family/presentation/pages/connect_family_page.dart';
import 'route_names.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
// import '../../features/auth/presentation/pages/register_page.dart';
// import '../../features/family/presentation/pages/connect_family_page.dart';
// import '../../features/family/presentation/pages/join_family_page.dart';
// import '../../features/permissions/presentation/pages/permission_setup_page.dart';
// import '../../features/permissions/presentation/pages/permission_guide_page.dart';
// import '../../features/dashboard/presentation/pages/child_dashboard_page.dart';
import '../../core/storage/local_storage.dart';
import '../injection_container.dart' as di;

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    redirect: _redirectLogic,
    routes: [
      // Splash Route
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // Onboarding Route
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // Auth Routes
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // GoRoute(
      //   path: RouteNames.register,
      //   name: 'register',
      //   builder: (context, state) => const RegisterPage(),
      // ),
      GoRoute(
        path: RouteNames.connectFamily,
        name: 'connect_family',
        builder: (context, state) => const ConnectFamilyPage(),
      ),

      // //   // Family Routes
      // //   GoRoute(
      // //     path: RouteNames.connectFamily,
      // //     name: 'connect_family',
      // //     builder: (context, state) => const ConnectFamilyPage(),
      // //   ),
      // //   GoRoute(
      // //     path: RouteNames.joinFamily,
      // //     name: 'join_family',
      // //     builder: (context, state) {
      // //       final familyCode = state.uri.queryParameters['code'];
      // //       return JoinFamilyPage(familyCode: familyCode);
      // //     },
      // //   ),

      // //   // Permission Routes
      // //   GoRoute(
      // //     path: RouteNames.permissionSetup,
      // //     name: 'permission_setup',
      // //     builder: (context, state) => const PermissionSetupPage(),
      // //   ),
      // //   GoRoute(
      // //     path: RouteNames.permissionGuide,
      // //     name: 'permission_guide',
      // //     builder: (context, state) {
      // //       final permissionType = state.uri.queryParameters['type'] ?? '';
      // //       return PermissionGuidePage(permissionType: permissionType);
      // //     },
      // //   ),

      // //   // Dashboard Route
      // //   GoRoute(
      // //     path: RouteNames.dashboard,
      // //     name: 'dashboard',
      // //     builder: (context, state) => const ChildDashboardPage(),
      // //   ),
    ],
    // errorBuilder: (context, state) => const ErrorPage(),
  );

  static String? _redirectLogic(BuildContext context, GoRouterState state) {
    final localStorage = di.sl<LocalStorage>();

    // Check if first time opening app
    final isFirstLaunch = localStorage.getBool('is_first_launch') ?? true;

    // Check authentication status
    final isAuthenticated =
        localStorage.getString('user_token')?.isNotEmpty ?? false;

    // Check family connection status
    final hasFamilyConnection =
        localStorage.getString('family_id')?.isNotEmpty ?? false;

    // Check permission setup status
    final hasPermissionSetup =
        localStorage.getBool('permission_setup_completed') ?? false;

    final currentPath = state.uri.path;

    // If on splash, don't redirect
    if (currentPath == RouteNames.splash) {
      return null;
    }

    // First launch flow
    if (isFirstLaunch && currentPath != RouteNames.onboarding) {
      return RouteNames.onboarding;
    }

    // Authentication flow
    if (!isAuthenticated &&
        !currentPath.startsWith('/auth') &&
        currentPath != RouteNames.onboarding) {
      return RouteNames.login;
    }

    // Family connection flow
    if (isAuthenticated &&
        !hasFamilyConnection &&
        !currentPath.startsWith('/family') &&
        !currentPath.startsWith('/auth') &&
        currentPath != RouteNames.onboarding) {
      return RouteNames.connectFamily;
    }

    // Permission setup flow
    if (isAuthenticated &&
        hasFamilyConnection &&
        !hasPermissionSetup &&
        !currentPath.startsWith('/permission') &&
        !currentPath.startsWith('/family') &&
        !currentPath.startsWith('/auth') &&
        currentPath != RouteNames.onboarding) {
      return RouteNames.permissionSetup;
    }

    // If all setup is complete, redirect to dashboard
    if (isAuthenticated &&
        hasFamilyConnection &&
        hasPermissionSetup &&
        (currentPath.startsWith('/auth') ||
            currentPath.startsWith('/family') ||
            currentPath.startsWith('/permission') ||
            currentPath == RouteNames.onboarding)) {
      return RouteNames.dashboard;
    }

    return null;
  }
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Halaman tidak ditemukan', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Mohon coba lagi nanti', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
