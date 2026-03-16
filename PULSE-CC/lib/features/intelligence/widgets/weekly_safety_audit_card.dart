import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/pulse_card.dart';
import '../intelligence_controller.dart';

class WeeklySafetyAuditCard extends StatelessWidget {
  final WeeklySafetyAudit audit;

  const WeeklySafetyAuditCard({super.key, required this.audit});

  @override
  Widget build(BuildContext context) {
    return PulseCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.danger, size: 18),
              const SizedBox(width: 8),
              Text(
                'Weekly Safety Audit',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          _buildRow('High Risk Area', audit.highRiskArea, isBold: true),
          const Divider(height: 1, color: AppColors.border),
          _buildRow('Accidents This Week', audit.accidentsThisWeek.toString(), valueColor: AppColors.danger, isBold: true),
          const Divider(height: 1, color: AppColors.border),
          _buildRow('Most Common Cause', audit.mostCommonCause, isBold: true),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
