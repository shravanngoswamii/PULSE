import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/intersection.dart';
import '../../../shared/widgets/section_label.dart';
import '../live_map_controller.dart';

class IntersectionInfoSheet extends ConsumerWidget {
  final Intersection intersection;
  final VoidCallback onOpenControl;
  final VoidCallback onClose;

  const IntersectionInfoSheet({
    super.key,
    required this.intersection,
    required this.onOpenControl,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(liveMapControllerProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    intersection.name,
                    style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Optimal Flow Phase',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.bar_chart, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Vehicles Waiting',
                  value: '${intersection.vehiclesWaiting}',
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Avg Delay',
                  value: '${intersection.avgDelaySeconds} sec',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onOpenControl,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'OPEN INTERSECTION CONTROL',
              style: AppTypography.labelLarge.copyWith(color: Colors.white, letterSpacing: 1.0),
            ),
          ),
          const SizedBox(height: 16),
          const SectionLabel(label: 'MAP VISUALIZATION LAYERS'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Signals', style: AppTypography.bodyMedium),
              Switch(
                value: controller.showSignals,
                activeThumbColor: AppColors.primary,
                onChanged: (_) => ref.read(liveMapControllerProvider.notifier).toggleSignalLayer(),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Emergency Vehicles', style: AppTypography.bodyMedium),
              Switch(
                value: controller.showEmergencyVehicles,
                activeThumbColor: AppColors.primary,
                onChanged: (_) => ref.read(liveMapControllerProvider.notifier).toggleVehicleLayer(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.micro.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary, fontSize: 24),
        ),
      ],
    );
  }
}
