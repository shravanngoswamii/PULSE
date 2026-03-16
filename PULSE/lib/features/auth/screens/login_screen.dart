import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/features/auth/providers/auth_provider.dart';
import 'package:pulse_ev/shared/widgets/app_button.dart';
import 'package:pulse_ev/shared/widgets/app_textfield.dart';
import 'package:pulse_ev/shared/widgets/section_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'driver@pulse.com');
  final _passwordController = TextEditingController(text: 'password123');
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _errorMessage = null);

    try {
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (!mounted) return;
      if (ref.read(authProvider) == AuthState.authenticated) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().contains('Invalid credentials')
            ? 'Invalid email or password'
            : 'Connection failed. Is the backend running?';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'P',
                    style: TextStyle(fontSize: 34, color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'PULSE',
                style: AppTextStyles.sectionTitle.copyWith(letterSpacing: 2),
              ),
              Text(
                'EMERGENCY VEHICLE SYSTEM',
                style: AppTextStyles.micro.copyWith(letterSpacing: 1),
              ),
              const SizedBox(height: 40),

              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.emergency.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.emergency.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.label.copyWith(color: AppColors.emergency),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SectionCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _emailController,
                        label: 'Email',
                        hintText: 'driver@pulse.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hintText: 'Enter password',
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        validator: (v) => (v == null || v.length < 4) ? 'Min 4 characters' : null,
                      ),
                      const SizedBox(height: 28),
                      AppButton(
                        text: 'LOGIN',
                        isLoading: authState == AuthState.loading,
                        onPressed: _handleLogin,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: AppTextStyles.label),
                  GestureDetector(
                    onTap: () => context.go('/signup'),
                    child: Text(
                      'Sign Up',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'V2.0 | SECURE EMERGENCY NETWORK',
                style: AppTextStyles.micro.copyWith(letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
