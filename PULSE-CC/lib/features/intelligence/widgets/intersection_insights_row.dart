import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/intersection.dart';
import '../../../shared/widgets/pulse_card.dart';

class IntersectionInsightsRow extends StatelessWidget {
  final List<Intersection> intersections;

  const IntersectionInsightsRow({super.key, required this.intersections});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: intersections.map((intersection) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: SizedBox(
              width: 180,
              height: 80,
              child: PulseCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.traffic, color: AppColors.primary, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            intersection.name,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          intersection.congestionLevel == CongestionLevel.high 
                              ? Icons.warning 
                              : Icons.check_circle,
                          color: intersection.congestionLevel == CongestionLevel.high 
                              ? AppColors.danger 
                              : AppColors.signalGreen,
                          size: 18,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Avg Delay: ${intersection.avgDelaySeconds} sec',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
