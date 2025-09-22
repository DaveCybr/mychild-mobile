
// features/onboarding/presentation/bloc/onboarding_event.dart
part of 'onboarding_bloc.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object> get props => [];
}

final class OnboardingStarted extends OnboardingEvent {}

final class OnboardingPageChanged extends OnboardingEvent {
  final int pageIndex;

  const OnboardingPageChanged(this.pageIndex);

  @override
  List<Object> get props => [pageIndex];
}

final class OnboardingNext extends OnboardingEvent {}

final class OnboardingPrevious extends OnboardingEvent {}

final class OnboardingSkip extends OnboardingEvent {}

final class OnboardingCompleted extends OnboardingEvent {}
