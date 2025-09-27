
// features/splash/presentation/bloc/splash_state.dart
part of 'splash_bloc.dart';

sealed class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object> get props => [];
}

final class SplashInitial extends SplashState {}

final class SplashLoading extends SplashState {}

final class SplashLoaded extends SplashState {}

final class SplashNavigateToOnboarding extends SplashState {}

final class SplashNavigateToAuth extends SplashState {}

final class SplashNavigateToFamily extends SplashState {}

final class SplashNavigateToPermission extends SplashState {}

final class SplashNavigateToDashboard extends SplashState {}
