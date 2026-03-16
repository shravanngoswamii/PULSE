import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/core/utils/validators.dart';
import 'package:pulse_ev/features/auth/providers/auth_provider.dart';
import 'package:pulse_ev/shared/widgets/app_button.dart';
import 'package:pulse_ev/shared/widgets/app_textfield.dart';
import 'package:pulse_ev/shared/widgets/section_card.dart';
import 'package:pulse_ev/shared/widgets/error_view.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignupSucceed() {
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/login'),
        ),
        title: Text(
          'PULSE',
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'P',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'PULSE',
                style: AppTextStyles.sectionTitle.copyWith(letterSpacing: 2),
              ),
              Text(
                'SMART EMERGENCY TRAFFIC SYSTEM',
                style: AppTextStyles.micro.copyWith(letterSpacing: 1),
              ),
              const SizedBox(height: 32),

              if (authState == AuthState.error) ...[
                ErrorView(message: authNotifier.errorMessage ?? 'Registration failed'),
                const SizedBox(height: 16),
              ],

              SectionCard(
                title: 'Create Account',
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: Icons.person_outline,
                        validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        controller: _emailController,
                        label: 'Vehicle ID / Email',
                        hintText: 'Enter ID or Email',
                        prefixIcon: Icons.badge_outlined,
                        validator: (v) => v?.contains('@') == true ? Validators.email(v) : Validators.vehicleId(v),
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        label: 'Password',
                        hintText: 'Create password',
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        controller: _passwordController,
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        label: 'Confirm Password',
                        hintText: 'Confirm password',
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        validator: (v) {
                          if (v != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        text: 'SIGN UP',
                        isLoading: authState == AuthState.loading,
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            await authNotifier.signup(
                              _nameController.text,
                              _emailController.text,
                              _passwordController.text,
                            );
                            if (ref.read(authProvider) == AuthState.authenticated) {
                              _onSignupSucceed();
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: AppTextStyles.label,
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text(
                      'Log in',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                'V1.0.4 | SECURE EMERGENCY NETWORK',
                style: AppTextStyles.micro.copyWith(letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
