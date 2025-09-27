// features/auth/presentation/bloc/auth_event.dart
part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthCheckStatus extends AuthEvent {}

final class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

final class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String role;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  List<Object> get props => [name, email, password, role];
}

final class AuthLogoutRequested extends AuthEvent {}

final class AuthRefreshRequested extends AuthEvent {}

final class AuthUpdateProfileRequested extends AuthEvent {
  final Map<String, dynamic> profileData;

  const AuthUpdateProfileRequested({
    required this.profileData,
  });

  @override
  List<Object> get props => [profileData];
}