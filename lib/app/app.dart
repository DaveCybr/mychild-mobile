
// app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
// import '../core/services/permission_service.dart';
// import '../shared/repositories/auth_repository.dart';
// import '../shared/repositories/family_repository.dart';
import '../features/splash/presentation/bloc/splash_bloc.dart';
// import '../features/auth/presentation/bloc/auth_bloc.dart';
// import '../features/family/presentation/bloc/family_bloc.dart';
// import '../features/permissions/presentation/bloc/permission_bloc.dart';
import 'injection_container.dart' as di;

class FamisafeChildApp extends StatelessWidget {
  const FamisafeChildApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SplashBloc()..add(SplashStarted()),
        ),
        // BlocProvider(
        //   create: (_) => AuthBloc(
        //     authRepository: di.sl<AuthRepository>(),
        //   ),
        // ),
        // BlocProvider(
        //   create: (_) => FamilyBloc(
        //     familyRepository: di.sl<FamilyRepository>(),
        //   ),
        // ),
        // BlocProvider(
        //   create: (_) => PermissionBloc(
        //     permissionService: di.sl<PermissionService>(),
        //   ),
        // ),
      ],
      child: MaterialApp.router(
        title: 'Famisafe Child',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: child!,
          );
        },
      ),
    );
  }
}