import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // PULSE Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/pulse_logo.png',
                        width: 120,
                        height: 120,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      AppStrings.appName,
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4.0,
                      ),
                    ),
                    const SizedBox(height: 48),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.tagline,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                AppStrings.version,
                style: AppTypography.micro.copyWith(
                  color: AppColors.textHint,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PulseLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.3) // Heartbeat line color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final h = size.height;
    final w = size.width;
    
    // Draw a heartbeat line across the middle
    path.moveTo(0, h * 0.5);
    path.lineTo(w * 0.2, h * 0.5);
    path.lineTo(w * 0.3, h * 0.2);
    path.lineTo(w * 0.45, h * 0.8);
    path.lineTo(w * 0.55, h * 0.4);
    path.lineTo(w * 0.65, h * 0.5);
    path.lineTo(w, h * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
