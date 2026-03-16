import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/traffic_alert.dart';
import '../../../shared/widgets/pulse_card.dart';
import '../../../shared/widgets/status_badge.dart';

class AlertFeedTile extends StatelessWidget {
  final TrafficAlert alert;
  final VoidCallback? onTap;

  const AlertFeedTile({
    super.key,
    required this.alert,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: PulseCard(
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _getBgColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIcon(),
                color: _getIconColor(),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    DateFormat('hh:mm a').format(alert.timestamp),
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildTrailing(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailing() {
    if (alert.type == AlertType.emergencyVehicle) {
      return Text(
        alert.vehicleId ?? '',
        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
      );
    }

    return _buildSeverityBadge();
  }

  Widget _buildSeverityBadge() {
    switch (alert.severity) {
      case Severity.high:
        return const StatusBadge(type: BadgeType.high);
      case Severity.medium:
        return const StatusBadge(type: BadgeType.medium);
      case Severity.low:
        return const StatusBadge(type: BadgeType.low);
    }
  }

  IconData _getIcon() {
    switch (alert.type) {
      case AlertType.accident:
        return Icons.warning;
      case AlertType.signalFailure:
        return Icons.traffic;
      case AlertType.emergencyVehicle:
        return Icons.emergency;
      case AlertType.congestion:
        return Icons.speed;
    }
  }

  Color _getIconColor() {
    switch (alert.type) {
      case AlertType.accident:
        return AppColors.danger;
      case AlertType.signalFailure:
        return AppColors.textHint;
      case AlertType.emergencyVehicle:
        return AppColors.primary;
      case AlertType.congestion:
        return AppColors.amber;
    }
  }

  Color _getBgColor() {
    switch (alert.type) {
      case AlertType.accident:
        return AppColors.dangerLight;
      case AlertType.signalFailure:
        return AppColors.background;
      case AlertType.emergencyVehicle:
        return AppColors.primaryLight;
      case AlertType.congestion:
        return AppColors.amberLight;
    }
  }
}
