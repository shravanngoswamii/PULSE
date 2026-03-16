import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/traffic_alert.dart';

class AlertFilterTabs extends StatelessWidget {
  final AlertType? activeFilter;
  final Function(AlertType?) onFilterChanged;

  const AlertFilterTabs({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              isActive: activeFilter == null,
              onTap: () => onFilterChanged(null),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Incidents',
              isActive: activeFilter == AlertType.accident,
              onTap: () => onFilterChanged(AlertType.accident),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Signals',
              isActive: activeFilter == AlertType.signalFailure,
              onTap: () => onFilterChanged(AlertType.signalFailure),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Emergencies',
              isActive: activeFilter == AlertType.emergencyVehicle,
              onTap: () => onFilterChanged(AlertType.emergencyVehicle),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
