import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/intersection.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/pulse_card.dart';

class IntersectionStatsRow extends StatelessWidget {
  final Intersection intersection;

  const IntersectionStatsRow({
    super.key,
    required this.intersection,
  });

  @override
  Widget build(BuildContext context) {
    return PulseCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatItem(
            icon: Icons.directions_car_outlined,
            label: 'VEHICLES WAITING',
            value: '${intersection.vehiclesWaiting}',
          ),
          const Divider(height: 32, color: AppColors.border),
          _StatItem(
            icon: Icons.access_time_outlined,
            label: 'AVERAGE DELAY',
            value: '${intersection.avgDelaySeconds} sec',
          ),
          const Divider(height: 32, color: AppColors.border),
          _StatItem(
            icon: Icons.bar_chart,
            label: 'CONGESTION LEVEL',
            value: intersection.congestionLevel.name.toUpperCase(),
            isBadge: true,
            congestionLevel: intersection.congestionLevel,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isBadge;
  final CongestionLevel? congestionLevel;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isBadge = false,
    this.congestionLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.micro.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            if (isBadge && congestionLevel != null)
              _buildCongestionBadge()
            else
              Text(
                value,
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const Spacer(),
        Icon(icon, color: AppColors.border, size: 28),
      ],
    );
  }

  Widget _buildCongestionBadge() {
    switch (congestionLevel!) {
      case CongestionLevel.low:
        return const StatusBadge(type: BadgeType.low);
      case CongestionLevel.moderate:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E6),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFFFD591)),
          ),
          child: Text(
            'MODERATE',
            style: AppTypography.micro.copyWith(
              color: const Color(0xFFD48806),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case CongestionLevel.high:
        return const StatusBadge(type: BadgeType.high);
    }
  }
}
