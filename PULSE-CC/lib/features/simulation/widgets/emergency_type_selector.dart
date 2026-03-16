import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/emergency_vehicle.dart';
import '../../../shared/widgets/pulse_card.dart';

class EmergencyTypeSelector extends StatelessWidget {
  final VehicleType selectedType;
  final ValueChanged<VehicleType> onTypeSelected;
  final VoidCallback onSetStart;
  final VoidCallback onSetDestination;

  const EmergencyTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
    required this.onSetStart,
    required this.onSetDestination,
  });

  @override
  Widget build(BuildContext context) {
    return PulseCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Emergency Simulation',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.medical_services, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildTypeChips(),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildRouteButton(
                  context,
                  Icons.flag_outlined,
                  'Set Start',
                  onSetStart,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildRouteButton(
                  context,
                  Icons.location_searching,
                  'Set Destination',
                  onSetDestination,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: VehicleType.values.map((type) {
          final isActive = selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onTypeSelected(type),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isActive ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    type.name[0].toUpperCase() + type.name.substring(1),
                    style: AppTypography.labelMedium.copyWith(
                      color: isActive ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRouteButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        onTap();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tap on map to ${label.toLowerCase()}')),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textHint, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
