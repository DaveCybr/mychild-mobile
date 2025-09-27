
// features/onboarding/presentation/bloc/onboarding_state.dart
part of 'onboarding_bloc.dart';

sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object> get props => [];
}

final class OnboardingInitial extends OnboardingState {}

final class OnboardingInProgress extends OnboardingState {
  final int currentIndex;
  final List<OnboardingData> slides;
  final bool isLastPage;

  const OnboardingInProgress({
    required this.currentIndex,
    required this.slides,
    required this.isLastPage,
  });

  @override
  List<Object> get props => [currentIndex, slides, isLastPage];
}

final class OnboardingFinished extends OnboardingState {}
