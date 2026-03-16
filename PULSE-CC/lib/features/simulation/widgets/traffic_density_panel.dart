import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/pulse_card.dart';
import '../simulation_controller.dart';

class TrafficDensityPanel extends StatelessWidget {
  final SimulationConfig config;
  final ValueChanged<double> onDensityChanged;
  final ValueChanged<int> onVehiclesPerMinuteChanged;
  final ValueChanged<int> onSignalDelayChanged;

  const TrafficDensityPanel({
    super.key,
    required this.config,
    required this.onDensityChanged,
    required this.onVehiclesPerMinuteChanged,
    required this.onSignalDelayChanged,
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
                'Traffic Simulation',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.traffic, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          
          // Density Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Traffic Density', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
              Text(
                '${(config.trafficDensityPercent * 100).toInt()}%',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: config.trafficDensityPercent,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primaryLight,
            onChanged: onDensityChanged,
          ),
          
          const Divider(height: 24, color: AppColors.border, thickness: 0.5),
          
          // Vehicles Per Minute
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Vehicles per Minute', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
              Container(
                width: 60,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    config.vehiclesPerMinute.toString(),
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
          
          const Divider(height: 24, color: AppColors.border, thickness: 0.5),
          
          // Signal Delay
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Signal Delay', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
              Text(
                '${config.signalDelaySeconds}s',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
