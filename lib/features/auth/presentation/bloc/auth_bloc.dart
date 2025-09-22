// features/auth/presentation/bloc/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../shared/models/user_model.dart';
import '../../../../shared/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthRefreshRequested>(_onRefreshRequested);
    on<AuthUpdateProfileRequested>(_onUpdateProfileRequested);
  }

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      
      if (isLoggedIn) {
        final cachedUser = await _authRepository.getCachedUser();
        
        if (cachedUser != null) {
          emit(AuthAuthenticated(user: cachedUser));
          
          // Try to refresh user data in background
          add(AuthRefreshRequested());
        } else {
          // Token exists but no cached user, try to get fresh data
          final response = await _authRepository.getCurrentUser();
          
          if (response.success && response.data != null) {
            emit(AuthAuthenticated(user: response.data!));
          } else {
            await _authRepository.clearUserData();
            emit(AuthUnauthenticated());
          }
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      await _authRepository.clearUserData();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final response = await _authRepository.login(
        email: event.email,
        password: event.password,
      );

      if (response.success && response.data != null) {
        emit(AuthLoginSuccess(user: response.data!));
        emit(AuthAuthenticated(user: response.data!));
      } else {
        emit(AuthError(
          message: response.message ?? 'Login failed',
        ));
      }
    } catch (e) {
      emit(AuthError(
        message: 'Login failed: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final response = await _authRepository.register(
        name: event.name,
        email: event.email,
        password: event.password,
        role: event.role,
      );

      if (response.success && response.data != null) {
        emit(AuthRegisterSuccess(user: response.data!));
        emit(AuthAuthenticated(user: response.data!));
      } else {
        emit(AuthError(
          message: response.message ?? 'Registration failed',
        ));
      }
    } catch (e) {
      emit(AuthError(
        message: 'Registration failed: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await _authRepository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      // Even if logout fails on server, clear local data
      await _authRepository.clearUserData();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRefreshRequested(
    AuthRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final response = await _authRepository.getCurrentUser();
      
      if (response.success && response.data != null) {
        if (state is AuthAuthenticated) {
          emit(AuthAuthenticated(user: response.data!));
        }
      }
    } catch (e) {
      // Ignore refresh errors - don't logout user just because refresh failed
    }
  }

  Future<void> _onUpdateProfileRequested(
    AuthUpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final response = await _authRepository.updateProfile(
        profileData: event.profileData,
      );

      if (response.success && response.data != null) {
        emit(AuthProfileUpdated(user: response.data!));
        emit(AuthAuthenticated(user: response.data!));
      } else {
        emit(AuthError(
          message: response.message ?? 'Profile update failed',
        ));
      }
    } catch (e) {
      emit(AuthError(
        message: 'Profile update failed: ${e.toString()}',
      ));
    }
  }
}