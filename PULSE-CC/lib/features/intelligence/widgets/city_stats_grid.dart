import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/pulse_card.dart';
import '../intelligence_controller.dart';

class CityStatsGrid extends StatelessWidget {
  final CityStats stats;

  const CityStatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildStatTile(
          icon: Icons.directions_car,
          iconColor: AppColors.primary,
          value: stats.vehiclesActive.toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},',
              ),
          label: 'Vehicles Active',
        ),
        _buildStatTile(
          icon: Icons.speed,
          iconColor: AppColors.primary,
          value: '${stats.avgSpeedKmh.toInt()} km/h',
          label: 'Avg Speed',
        ),
        _buildStatTile(
          icon: Icons.traffic,
          iconColor: AppColors.textHint,
          value: stats.congestionZones.toString().padLeft(2, '0'),
          label: 'Congestion Zones',
        ),
        _buildStatTile(
          icon: Icons.warning_amber,
          iconColor: AppColors.danger,
          value: '${stats.trafficAlertsToday} Today',
          label: 'Traffic Alerts',
          valueColor: AppColors.danger,
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return PulseCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const Spacer(),
          Text(
            value,
            style: AppTypography.displayMedium.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
