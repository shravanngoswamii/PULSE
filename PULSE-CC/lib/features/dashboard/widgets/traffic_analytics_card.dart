import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/pulse_card.dart';
import '../dashboard_controller.dart';

class TrafficAnalyticsCard extends ConsumerWidget {
  const TrafficAnalyticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    final status = state.systemStatus;

    // Find the most congested intersection
    final congested = state.intersections
        .where((i) => i.congestionLevel.name == 'high')
        .toList();
    final peakArea = congested.isNotEmpty
        ? congested.first.district
        : (state.intersections.isNotEmpty ? state.intersections.first.district : 'N/A');
    final peakDelay = congested.isNotEmpty
        ? '${congested.first.avgDelaySeconds}s delay'
        : '${status.averageDelaySeconds}s avg';

    return PulseCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.trending_up, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PEAK CONGESTION AREA',
                  style: AppTypography.micro.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        peakArea,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      peakDelay,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
