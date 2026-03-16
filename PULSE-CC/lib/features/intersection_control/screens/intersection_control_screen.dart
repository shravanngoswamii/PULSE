import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/intersection.dart';
import '../../../shared/widgets/pulse_app_bar.dart';
import '../../../shared/widgets/pulse_bottom_nav.dart';
import '../../../shared/widgets/pulse_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../intersection_controller.dart';
import '../widgets/emergency_alert_banner.dart';
import '../widgets/signal_schematic_view.dart';
import '../widgets/force_signal_button.dart';
import '../widgets/intersection_stats_row.dart';

class IntersectionControlScreen extends ConsumerWidget {
  final String intersectionId;

  const IntersectionControlScreen({
    super.key,
    required this.intersectionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(intersectionControllerProvider(intersectionId));
    final controller = ref.read(intersectionControllerProvider(intersectionId).notifier);

    // Show success snackbar
    ref.listen(intersectionControllerProvider(intersectionId), (previous, next) {
      if (next.successMessage != null && previous?.successMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.signalGreen,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final intersection = state.intersection;
    
    return LoadingOverlay(
      isLoading: state.isLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PulseAppBar(
          title: 'INTERSECTION CONTROL',
          subtitle: intersection?.name ?? 'Loading...',
          showSettings: true,
        ),
        body: intersection == null 
          ? const Center(child: Text('Intersection not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            const SizedBox(height: 16),

            if (state.hasActiveEmergency && state.approachingVehicle != null) ...[
              EmergencyAlertBanner(
                vehicle: state.approachingVehicle!,
                onActivateCorridor: controller.activateGreenCorridor,
              ),
              const SizedBox(height: 16),
            ],

            PulseCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _MetadataRow(label: 'NAME', value: intersection.name),
                  const Divider(height: 24, color: AppColors.border),
                  _MetadataRow(label: 'DISTRICT', value: intersection.district),
                  const Divider(height: 24, color: AppColors.border),
                  _MetadataRow(
                    label: 'SIGNAL MODE',
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Automatic  ', style: AppTypography.bodyMedium),
                        _buildModeBadge(intersection.signalMode),
                      ],
                    ),
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  _MetadataRow(label: 'LAST OVERRIDE', value: 'None'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            PulseCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SIGNAL SCHEMATIC',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.signalGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.signalGreen.withOpacity(0.3)),
                        ),
                        child: Text(
                          'LIVE DATA',
                          style: AppTypography.micro.copyWith(
                            color: AppColors.signalGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SignalSchematicView(
                    selectedLane: state.selectedLane,
                    intersection: intersection,
                    onLaneSelected: controller.selectLane,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'SELECTED SIGNAL: ${state.selectedLane} LANE',
              style: AppTypography.micro.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),

            ForceSignalButton(
              phase: SignalPhase.green,
              onTap: controller.forceGreen,
            ),
            const SizedBox(height: 10),

            ForceSignalButton(
              phase: SignalPhase.red,
              onTap: controller.forceRed,
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: controller.restoreAutomatic,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'RESTORE AUTOMATIC  »',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            IntersectionStatsRow(intersection: intersection),
            
            SizedBox(height: 24 + 64 + MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
      bottomNavigationBar: const PulseBottomNav(currentIndex: 2), 
    ),);
  }

  Widget _buildModeBadge(SignalMode mode) {
    switch (mode) {
      case SignalMode.automatic:
        return const StatusBadge(type: BadgeType.normal);
      case SignalMode.emergency:
        return const StatusBadge(type: BadgeType.high);
      case SignalMode.manual:
        return const StatusBadge(type: BadgeType.medium);
    }
  }
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _MetadataRow({required this.label, this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.micro.copyWith(color: AppColors.textSecondary),
        ),
        if (valueWidget != null)
          valueWidget!
        else
          Text(
            value ?? '',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
