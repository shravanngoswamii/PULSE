import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class EtaChip extends StatelessWidget {
  final int etaMinutes;
  final String? vehicleId;

  const EtaChip({
    super.key,
    required this.etaMinutes,
    this.vehicleId,
  });

  @override
  Widget build(BuildContext context) {
    final text = vehicleId != null ? '$vehicleId: ${etaMinutes}m ETA' : '${etaMinutes}m ETA';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
