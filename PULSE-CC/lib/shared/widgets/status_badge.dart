import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

enum BadgeType { high, medium, low, live, online, pending, normal }

class StatusBadge extends StatelessWidget {
  final BadgeType type;

  const StatusBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;
    bool showDot = false;

    switch (type) {
      case BadgeType.high:
        bg = AppColors.dangerLight;
        text = AppColors.dangerDark;
        label = 'HIGH';
        break;
      case BadgeType.medium:
        bg = AppColors.amberLight;
        text = const Color(0xFF854F0B);
        label = 'MEDIUM';
        break;
      case BadgeType.low:
        bg = AppColors.primaryLight;
        text = AppColors.primaryDark;
        label = 'LOW';
        break;
      case BadgeType.live:
        bg = AppColors.primaryLight;
        text = AppColors.primaryDark;
        label = 'LIVE';
        showDot = true;
        break;
      case BadgeType.online:
        bg = AppColors.primaryLight;
        text = AppColors.primaryDark;
        label = 'ONLINE';
        showDot = true;
        break;
      case BadgeType.pending:
        bg = AppColors.background;
        text = AppColors.textSecondary;
        label = 'PENDING';
        break;
      case BadgeType.normal:
        bg = AppColors.background;
        text = AppColors.textSecondary;
        label = 'NORMAL';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.micro.copyWith(color: text, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
