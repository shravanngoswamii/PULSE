import 'package:flutter/material.dart';
import 'package:pulse_ev/config/app_theme.dart';

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final String? title;

  const SectionCard({
    super.key,
    required this.child,
    this.padding,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 18, top: 16, right: 18),
              child: Text(
                title!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
            child: child,
          ),
        ],
      ),
    );
  }
}
