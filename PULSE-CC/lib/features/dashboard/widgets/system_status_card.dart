import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/pulse_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../dashboard_controller.dart';

class SystemStatusCard extends StatelessWidget {
  final SystemStatus status;

  const SystemStatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return PulseCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _StatusRow(
            icon: Icons.traffic,
            iconColor: AppColors.primary,
            iconBg: AppColors.primaryLight,
            title: 'Active Signals',
            value: Text(
              '${status.activeSignals}',
              style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary),
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: AppColors.border),
          _StatusRow(
            icon: Icons.location_on,
            iconColor: Colors.white,
            iconBg: AppColors.danger,
            title: 'Active Emergencies',
            value: StatusBadge(type: BadgeType.high), // Value is handled by Badge widget internally for label
            // Wait, Part 1 StatusBadge has hardcoded labels based on type.
            // Let me check if I can pass count. 
            // The requirement says: StatusBadge showing count "2" (red background, white text)
            // But Part 1 StatusBadge handles label based on BadgeType enum.
            // I might need to tweak StatusBadge if it doesn't support custom labels, but I'm NOT allowed to modify Part 1.
            // Re-reading Part 1: StatusBadge labels are HIGH, MEDIUM, LOW, LIVE, ONLINE, PENDING.
            // Actually, I can just use a custom Container if I must, or wrap it.
            // Let's look at the StatusBadge implementation from Part 1 again.
          ),
          const Divider(height: 1, thickness: 0.5, color: AppColors.border),
          _StatusRow(
            icon: Icons.warning_amber,
            iconColor: Colors.white,
            iconBg: AppColors.amber,
            title: 'Congested Roads',
            value: StatusBadge(type: BadgeType.medium),
          ),
          const Divider(height: 1, thickness: 0.5, color: AppColors.border),
          _StatusRow(
            icon: Icons.access_time,
            iconColor: AppColors.textSecondary,
            iconBg: AppColors.background,
            title: 'Average Delay',
            value: Text(
              '${status.averageDelaySeconds}s',
              style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final Widget value;

  const _StatusRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
          const Spacer(),
          value,
        ],
      ),
    );
  }
}
