import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/extensions.dart';

class PulseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showSettings;
  final bool showProfile;
  final List<Widget>? actions;

  const PulseAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showSettings = true,
    this.showProfile = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
            ),
        ],
      ),
      actions: [
        if (actions != null) ...actions!,
        if (showSettings)
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            onPressed: () {
              context.push('/settings');
            },
          ),
        if (showProfile)
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
            child: ClipOval(
              child: Image.asset(
                'assets/images/pulse_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}
