import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/active_mission.dart';
import '../../../data/models/emergency_vehicle.dart';
import '../../../shared/widgets/pulse_card.dart';

class ActiveMissionTile extends StatelessWidget {
  final ActiveMission mission;

  const ActiveMissionTile({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    final isPrimary = mission.vehicle.type == VehicleType.ambulance;

    return PulseCard(
      padding: isPrimary ? const EdgeInsets.all(16) : const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => context.go('/emergencies'),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 3,
              color: isPrimary ? AppColors.primary : AppColors.amber,
            ),
            const SizedBox(width: 12),
            // Leading Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getIconBgColor(mission.vehicle.type),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconData(mission.vehicle.type),
                color: _getIconColor(mission.vehicle.type),
              ),
            ),
            const SizedBox(width: 12),
            // Middle Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${mission.vehicle.type == VehicleType.ambulance ? 'Ambulance' : mission.vehicle.type == VehicleType.fire ? 'Fire Truck' : 'Police'} [${mission.vehicle.id}]',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
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
            // Trailing column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ETA',
                  style: AppTypography.micro.copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  '${mission.vehicle.etaSeconds ~/ 60}m',
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(VehicleType type) {
    switch (type) {
      case VehicleType.ambulance:
        return Icons.local_hospital;
      case VehicleType.fire:
        return Icons.fire_truck;
      case VehicleType.police:
        return Icons.shield;
    }
  }

  Color _getIconBgColor(VehicleType type) {
    switch (type) {
      case VehicleType.ambulance:
        return AppColors.primaryLight;
      case VehicleType.fire:
        return Colors.orange.withOpacity(0.2);
      case VehicleType.police:
        return Colors.blue.withOpacity(0.2);
    }
  }

  Color _getIconColor(VehicleType type) {
    switch (type) {
      case VehicleType.ambulance:
        return AppColors.primary;
      case VehicleType.fire:
        return Colors.orange;
      case VehicleType.police:
        return Colors.blue;
    }
  }
}
