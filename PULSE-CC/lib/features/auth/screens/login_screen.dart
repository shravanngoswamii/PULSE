import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/pulse_card.dart';
import '../auth_controller.dart';
import '../widgets/secure_input_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authorityIdController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _authorityIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authControllerProvider.notifier).login(
            _authorityIdController.text,
            _passwordController.text,
          );
      if (success && mounted) {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Show error snackbar if needed
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        context.showSnackBar(next.errorMessage!, isError: true);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Area
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hub, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.appSubtitle,
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Header Section
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/images/pulse_logo.png',
                        width: 48,
                        height: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.appName,
                      style: AppTypography.displayMedium
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    Text(
                      AppStrings.appSubtitle,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),

                    // Form Card
                    PulseCard(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppStrings.loginTitle,
                              textAlign: TextAlign.center,
                              style: AppTypography.labelLarge.copyWith(
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SecureInputField(
                              label: 'Email / Authority ID',
                              hint: 'operator@pulse.city',
                              icon: Icons.badge_outlined,
                              controller: _authorityIdController,
                              validator: Validators.validateAuthorityId,
                            ),
                            const SizedBox(height: 16),
                            SecureInputField(
                              label: 'Password',
                              hint: '••••••••••••',
                              icon: Icons.lock_outlined,
                              isPassword: true,
                              controller: _passwordController,
                              validator: Validators.validatePassword,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed:
                                  authState.isLoading ? null : _handleLogin,
                              child: authState.isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      '${AppStrings.loginButton} \u2192',
                                      style: AppTypography.labelLarge.copyWith(
                                          color: Colors.white,
                                          letterSpacing: 1.0),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    // Status Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.systemOnline,
                            style: AppTypography.micro.copyWith(
                              color: AppColors.primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Footer
            Column(
              children: [
                Text(
                  AppStrings.smartTrafficControl,
                  style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  AppStrings.cityInfrastructure,
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
