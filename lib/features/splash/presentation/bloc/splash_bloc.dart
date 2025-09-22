
// features/splash/presentation/bloc/splash_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../app/injection_container.dart' as di;

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final LocalStorage _localStorage = di.sl<LocalStorage>();
  final SecureStorage _secureStorage = di.sl<SecureStorage>();

  SplashBloc() : super(SplashInitial()) {
    on<SplashStarted>(_onSplashStarted);
    on<SplashCompleted>(_onSplashCompleted);
  }

  Future<void> _onSplashStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    emit(SplashLoading());
    
    // Simulate splash screen duration
    await Future.delayed(const Duration(seconds: 2));
    
    add(SplashCompleted());
  }

  Future<void> _onSplashCompleted(
    SplashCompleted event,
    Emitter<SplashState> emit,
  ) async {
    emit(SplashLoaded());
    
    // Check app state and determine next route
    final appState = await _checkAppState();
    
    switch (appState) {
      case AppState.firstLaunch:
        emit(SplashNavigateToOnboarding());
        break;
      case AppState.needAuth:
        emit(SplashNavigateToAuth());
        break;
      case AppState.needFamilyConnection:
        emit(SplashNavigateToFamily());
        break;
      case AppState.needPermissionSetup:
        emit(SplashNavigateToPermission());
        break;
      case AppState.ready:
        emit(SplashNavigateToDashboard());
        break;
    }
  }

  Future<AppState> _checkAppState() async {
    try {
      // Check if first launch
      final isFirstLaunch = _localStorage.getBool(StorageKeys.isFirstLaunch) ?? true;
      if (isFirstLaunch) {
        return AppState.firstLaunch;
      }

      // Check authentication
      final token = await _secureStorage.getString(StorageKeys.userToken);
      if (token == null || token.isEmpty) {
        return AppState.needAuth;
      }

      // Check family connection
      final familyId = _localStorage.getString(StorageKeys.familyId);
      if (familyId == null || familyId.isEmpty) {
        return AppState.needFamilyConnection;
      }

      // Check permission setup
      final permissionSetupCompleted = _localStorage.getBool(StorageKeys.permissionSetupCompleted) ?? false;
      if (!permissionSetupCompleted) {
        return AppState.needPermissionSetup;
      }

      return AppState.ready;
    } catch (e) {
      // If any error occurs, start from auth
      return AppState.needAuth;
    }
  }
}

enum AppState {
  firstLaunch,
  needAuth,
  needFamilyConnection,
  needPermissionSetup,
  ready,
}
