import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../data/models/active_mission.dart';

class JunctionClearanceColumn extends StatelessWidget {
  final Map<String, ClearanceStatus> clearance;

  const JunctionClearanceColumn({
    super.key,
    required this.clearance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: clearance.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _buildBadge(entry.value),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBadge(ClearanceStatus status) {
    switch (status) {
      case ClearanceStatus.green:
      case ClearanceStatus.cleared:
        return const StatusBadge(type: BadgeType.low);
      case ClearanceStatus.pending:
        return const StatusBadge(type: BadgeType.pending);
    }
  }
}
