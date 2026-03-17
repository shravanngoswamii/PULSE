import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/pulse_card.dart';
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
            value: _CountBadge(
              count: status.activeEmergencies,
              color: AppColors.danger,
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: AppColors.border),
          _StatusRow(
            icon: Icons.warning_amber,
            iconColor: Colors.white,
            iconBg: AppColors.amber,
            title: 'Congested Roads',
            value: _CountBadge(
              count: status.congestedRoads,
              color: AppColors.amber,
            ),
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

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: AppTypography.labelMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
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
