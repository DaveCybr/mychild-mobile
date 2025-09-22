// features/auth/presentation/bloc/auth_state.dart
part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object> get props => [user];
}

final class AuthUnauthenticated extends AuthState {}

final class AuthError extends AuthState {
  final String message;
  final String? errorCode;

  const AuthError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

final class AuthLoginSuccess extends AuthState {
  final UserModel user;

  const AuthLoginSuccess({required this.user});

  @override
  List<Object> get props => [user];
}

final class AuthRegisterSuccess extends AuthState {
  final UserModel user;

  const AuthRegisterSuccess({required this.user});

  @override
  List<Object> get props => [user];
}

final class AuthProfileUpdated extends AuthState {
  final UserModel user;

  const AuthProfileUpdated({required this.user});

  @override
  List<Object> get props => [user];
}