import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/shared/widgets/loading_indicator.dart';
import 'package:pulse_ev/features/auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Show splash for at least 2 seconds as per design
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      ref.read(authProvider.notifier).checkSession(),
    ]);

    if (mounted) {
      final authState = ref.read(authProvider);
      if (authState == AuthState.authenticated) {
        context.go('/dashboard');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: AppColors.background),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'P',
                  style: TextStyle(
                    fontSize: 56,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'PULSE',
              style: AppTextStyles.title.copyWith(
                letterSpacing: 4,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 48),
            const AppLoadingIndicator(),
            const SizedBox(height: 16),
            Text(
              'Initializing Neural Traffic Grid...',
              style: AppTextStyles.label,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'V1.0.4 | SECURE EMERGENCY NETWORK',
                style: AppTextStyles.micro.copyWith(letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
