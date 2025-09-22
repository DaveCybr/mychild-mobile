// features/auth/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Import yang diperlukan untuk LocalStorage
import '../../../../core/storage/local_storage.dart';
import '../../../../core/constants/storage_keys.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validator.dart';
import '../../../../shared/widgets/common_button.dart';
import '../../../../shared/widgets/common_textfield.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_form.dart';
// import '../widgets/auth_form.dart';
// import '../widgets/social_login_buttons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          setState(() {
            _isLoading = state is AuthLoading;
          });

          if (state is AuthError) {
            context.showSnackBar(
              state.message,
              backgroundColor: AppColors.error,
            );
          } else if (state is AuthAuthenticated) {
            // Navigate based on user's setup status
            if (state.user.hasFamily) {
              final permissionSetupCompleted = context
                  .read<LocalStorage>()
                  .getBool(StorageKeys.permissionSetupCompleted) ?? false;
              
              if (permissionSetupCompleted) {
                context.go(RouteNames.dashboard);
              } else {
                context.go(RouteNames.permissionSetup);
              }
            } else {
              context.go(RouteNames.connectFamily);
            }
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                
                // Header
                _buildHeader(),
                
                const SizedBox(height: 40),
                
                // Login Form
                AuthForm(
                  formKey: _formKey,
                  isLoading: _isLoading,
                  children: [
                    CommonTextField(
                      label: 'Email',
                      hint: 'Masukkan email Anda',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    CommonTextField(
                      label: 'Password',
                      hint: 'Masukkan password Anda',
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: Validators.password,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      onEditingComplete: _handleLogin,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password
                          context.showSnackBar('Fitur lupa password akan segera tersedia');
                        },
                        child: Text(
                          'Lupa Password?',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Login Button
                    CommonButton(
                      text: 'Masuk',
                      onPressed: _isLoading ? null : _handleLogin,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // OR Divider
                _buildOrDivider(),
                
                const SizedBox(height: 24),
                
                // Social Login
                // const SocialLoginButtons(),
                
                const SizedBox(height: 40),
                
                // Register Link
                _buildRegisterLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Logo
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.family_restroom,
            color: AppColors.white,
            size: 32,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Title
        Text(
          'Selamat Datang Kembali',
          style: AppTextStyles.displaySmall,
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          'Masuk untuk melanjutkan perlindungan keluarga Anda',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'atau',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Belum punya akun? ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          TextButton(
            onPressed: () {
              context.go(RouteNames.register);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Daftar',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
