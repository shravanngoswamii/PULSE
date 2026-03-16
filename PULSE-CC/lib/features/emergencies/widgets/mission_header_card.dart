import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/emergency_vehicle.dart';
import '../../../data/models/active_mission.dart';
import '../../../shared/widgets/pulse_card.dart';
import '../../../shared/widgets/eta_chip.dart';

class MissionHeaderCard extends StatelessWidget {
  final ActiveMission mission;
  final bool isPrimary;

  const MissionHeaderCard({
    super.key,
    required this.mission,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return PulseCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getBgColor(),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIcon(),
              color: _getIconColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getTypeName()} ${mission.vehicle.id}',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${mission.vehicle.originName} → ${mission.vehicle.destinationName}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${mission.vehicle.etaSeconds ~/ 60} min ETA',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              // We can put some status text here if needed
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (mission.vehicle.type) {
      case VehicleType.ambulance:
        return Icons.local_hospital;
      case VehicleType.fire:
        return Icons.fire_truck;
      case VehicleType.police:
        return Icons.shield;
    }
  }

  Color _getIconColor() {
    switch (mission.vehicle.type) {
      case VehicleType.ambulance:
        return AppColors.primary;
      case VehicleType.fire:
        return Colors.orange;
      case VehicleType.police:
        return Colors.blue;
    }
  }

  Color _getBgColor() {
    switch (mission.vehicle.type) {
      case VehicleType.ambulance:
        return AppColors.primaryLight;
      case VehicleType.fire:
        return Colors.orange.withOpacity(0.1);
      case VehicleType.police:
        return Colors.blue.withOpacity(0.1);
    }
  }

  String _getTypeName() {
    switch (mission.vehicle.type) {
      case VehicleType.ambulance:
        return 'Ambulance';
      case VehicleType.fire:
        return 'Fire Truck';
      case VehicleType.police:
        return 'Police';
    }
  }
}
