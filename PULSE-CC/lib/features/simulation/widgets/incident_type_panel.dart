import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/traffic_alert.dart';
import '../../../shared/widgets/pulse_card.dart';
import '../simulation_controller.dart';

class IncidentTypePanel extends StatelessWidget {
  final SimulationConfig config;
  final ValueChanged<AlertType?> onIncidentTypeChanged;
  final ValueChanged<String> onLocationChanged;
  final ValueChanged<Severity> onSeverityChanged;

  const IncidentTypePanel({
    super.key,
    required this.config,
    required this.onIncidentTypeChanged,
    required this.onLocationChanged,
    required this.onSeverityChanged,
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
                'Incident Simulation',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.diamond, color: AppColors.danger, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'INCIDENT TYPE',
            style: AppTypography.micro.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AlertType?>(
                isExpanded: true,
                value: config.incidentType,
                hint: const Text('None'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...AlertType.values.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                      )),
                ],
                onChanged: onIncidentTypeChanged,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                config.incidentLocation ?? 'Not set',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Map selection available in full build')),
                  );
                },
                child: Text(
                  'Select on Map',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSeverityChip(context, Severity.low),
              _buildSeverityChip(context, Severity.medium),
              _buildSeverityChip(context, Severity.high),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChip(BuildContext context, Severity severity) {
    final isActive = config.incidentSeverity == severity;
    Color bgColor = AppColors.background;
    Color textColor = AppColors.textSecondary;
    BorderSide border = const BorderSide(color: AppColors.border);

    if (isActive) {
      switch (severity) {
        case Severity.low:
          bgColor = AppColors.primaryLight;
          textColor = AppColors.primary;
          border = BorderSide.none;
          break;
        case Severity.medium:
          bgColor = AppColors.amberLight;
          textColor = AppColors.amber;
          border = BorderSide.none;
          break;
        case Severity.high:
          bgColor = AppColors.dangerLight;
          textColor = AppColors.danger;
          border = BorderSide.none;
          break;
      }
    }

    return InkWell(
      onTap: () => onSeverityChanged(severity),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: isActive ? null : Border.fromBorderSide(border),
        ),
        child: Center(
          child: Text(
            severity.name[0].toUpperCase() + severity.name.substring(1),
            style: AppTypography.labelMedium.copyWith(
              color: textColor,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
