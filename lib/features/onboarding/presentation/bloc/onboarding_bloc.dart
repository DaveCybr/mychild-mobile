
// features/onboarding/presentation/bloc/onboarding_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/onboarding_data.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../app/injection_container.dart' as di;

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final LocalStorage _localStorage = di.sl<LocalStorage>();
  int _currentIndex = 0;
  final List<OnboardingData> _slides = OnboardingData.slides;

  OnboardingBloc() : super(OnboardingInitial()) {
    on<OnboardingStarted>(_onOnboardingStarted);
    on<OnboardingPageChanged>(_onPageChanged);
    on<OnboardingNext>(_onNext);
    on<OnboardingPrevious>(_onPrevious);
    on<OnboardingSkip>(_onSkip);
    on<OnboardingCompleted>(_onCompleted);
  }

  void _onOnboardingStarted(
    OnboardingStarted event,
    Emitter<OnboardingState> emit,
  ) {
    _currentIndex = 0;
    emit(OnboardingInProgress(
      currentIndex: _currentIndex,
      slides: _slides,
      isLastPage: _currentIndex == _slides.length - 1,
    ));
  }

  void _onPageChanged(
    OnboardingPageChanged event,
    Emitter<OnboardingState> emit,
  ) {
    _currentIndex = event.pageIndex;
    emit(OnboardingInProgress(
      currentIndex: _currentIndex,
      slides: _slides,
      isLastPage: _currentIndex == _slides.length - 1,
    ));
  }

  void _onNext(
    OnboardingNext event,
    Emitter<OnboardingState> emit,
  ) {
    if (_currentIndex < _slides.length - 1) {
      _currentIndex++;
      emit(OnboardingInProgress(
        currentIndex: _currentIndex,
        slides: _slides,
        isLastPage: _currentIndex == _slides.length - 1,
      ));
    } else {
      add(OnboardingCompleted());
    }
  }

  void _onPrevious(
    OnboardingPrevious event,
    Emitter<OnboardingState> emit,
  ) {
    if (_currentIndex > 0) {
      _currentIndex--;
      emit(OnboardingInProgress(
        currentIndex: _currentIndex,
        slides: _slides,
        isLastPage: _currentIndex == _slides.length - 1,
      ));
    }
  }

  void _onSkip(
    OnboardingSkip event,
    Emitter<OnboardingState> emit,
  ) {
    add(OnboardingCompleted());
  }

  Future<void> _onCompleted(
    OnboardingCompleted event,
    Emitter<OnboardingState> emit,
  ) async {
    await _localStorage.setBool(StorageKeys.isFirstLaunch, false);
    await _localStorage.setBool(StorageKeys.onboardingCompleted, true);
    emit(OnboardingFinished());
  }
}
