import 'package:flutter/material.dart';
import 'package:pulse_ev/config/app_theme.dart';

enum ButtonVariant { primary, secondary, emergency }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: AppSpacing.buttonHeight,
        decoration: BoxDecoration(
          gradient: _getGradient(),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _getShadow(),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (variant == ButtonVariant.emergency) ...[
                      const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ] else if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text.toUpperCase(),
                      style: AppTextStyles.label.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  LinearGradient _getGradient() {
    switch (variant) {
      case ButtonVariant.primary:
        return AppColors.primaryGradient;
      case ButtonVariant.secondary:
        return AppColors.darkGradient;
      case ButtonVariant.emergency:
        return AppColors.emergencyGradient;
    }
  }

  List<BoxShadow> _getShadow() {
    switch (variant) {
      case ButtonVariant.primary:
        return AppShadows.glow;
      case ButtonVariant.secondary:
        return AppShadows.elevated;
      case ButtonVariant.emergency:
        return [
          BoxShadow(
            color: AppColors.emergency.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
    }
  }
}
