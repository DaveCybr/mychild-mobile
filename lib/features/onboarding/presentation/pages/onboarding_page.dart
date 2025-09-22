
// features/onboarding/presentation/pages/onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/common_button.dart';
import '../bloc/onboarding_bloc.dart';
import '../widgets/onboarding_slide.dart';
import '../widgets/page_indicator.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    context.read<OnboardingBloc>().add(OnboardingStarted());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingBloc()..add(OnboardingStarted()),
      child: BlocListener<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingFinished) {
            context.go(RouteNames.login);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: BlocBuilder<OnboardingBloc, OnboardingState>(
              builder: (context, state) {
                if (state is OnboardingInProgress) {
                  return Column(
                    children: [
                      // Skip button
                      Padding(
                        padding: const EdgeInsets.all(AppConstants.defaultPadding),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: TextButton(
                            onPressed: () {
                              context.read<OnboardingBloc>().add(OnboardingSkip());
                            },
                            child: Text(
                              'Lewati',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Page view
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: state.slides.length,
                          onPageChanged: (index) {
                            context.read<OnboardingBloc>().add(
                              OnboardingPageChanged(index),
                            );
                          },
                          itemBuilder: (context, index) {
                            return OnboardingSlide(slide: state.slides[index]);
                          },
                        ),
                      ),
                      
                      // Bottom section
                      Padding(
                        padding: const EdgeInsets.all(AppConstants.largePadding),
                        child: Column(
                          children: [
                            // Page indicator
                            PageIndicator(
                              currentIndex: state.currentIndex,
                              totalPages: state.slides.length,
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Navigation buttons
                            Row(
                              children: [
                                // Previous button
                                if (state.currentIndex > 0)
                                  Expanded(
                                    child: CommonButton.outlined(
                                      text: 'Sebelumnya',
                                      onPressed: () {
                                        _pageController.previousPage(
                                          duration: AppConstants.shortAnimationDuration,
                                          curve: Curves.easeInOut,
                                        );
                                        context.read<OnboardingBloc>().add(
                                          OnboardingPrevious(),
                                        );
                                      },
                                    ),
                                  )
                                else
                                  const Spacer(),
                                
                                if (state.currentIndex > 0)
                                  const SizedBox(width: AppConstants.defaultPadding),
                                
                                // Next/Finish button
                                Expanded(
                                  flex: state.currentIndex > 0 ? 1 : 2,
                                  child: CommonButton(
                                    text: state.isLastPage ? 'Mulai' : 'Selanjutnya',
                                    onPressed: () {
                                      if (state.isLastPage) {
                                        context.read<OnboardingBloc>().add(
                                          OnboardingCompleted(),
                                        );
                                      } else {
                                        _pageController.nextPage(
                                          duration: AppConstants.shortAnimationDuration,
                                          curve: Curves.easeInOut,
                                        );
                                        context.read<OnboardingBloc>().add(
                                          OnboardingNext(),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}