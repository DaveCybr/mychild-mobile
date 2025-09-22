// features/splash/presentation/bloc/splash_event.dart
part of 'splash_bloc.dart';

sealed class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object> get props => [];
}

final class SplashStarted extends SplashEvent {}

final class SplashCompleted extends SplashEvent {}
