import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/features/mission/providers/mission_summary_provider.dart';
import 'package:pulse_ev/shared/widgets/app_button.dart';
import 'package:pulse_ev/shared/widgets/section_card.dart';
import 'package:pulse_ev/shared/widgets/pulse_map.dart';
import 'package:pulse_ev/shared/widgets/loading_indicator.dart';
import 'package:pulse_ev/shared/widgets/error_view.dart';

class MissionSummaryScreen extends ConsumerWidget {
  const MissionSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(missionSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(
          'MISSION SUMMARY',
          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
        centerTitle: true,
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(missionSummaryProvider),
        ),
        data: (summary) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Text(
                'TRAFFIC SCENARIO SIMULATOR',
                style: AppTextStyles.micro.copyWith(letterSpacing: 1, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // 1. Mission Completed Banner
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '[ MISSION COMPLETED ✓ ]',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Vehicle:', summary.vehicleId),
                    _buildInfoRow('Driver:', summary.driverName),
                    _buildInfoRow('Start Time:', summary.startTime),
                    _buildInfoRow('End Time:', summary.endTime),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Route Summary
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('[ ROUTE SUMMARY ]', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        const PulseMap(),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              'Central Station → City Hospital',
                              style: AppTextStyles.micro.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Mission Statistics
              SectionCard(
                title: '[ MISSION STATISTICS ]',
                child: Column(
                  children: [
                    _buildStatLine('Distance Travelled:', '${summary.distanceTravelled} km'),
                    _buildStatLine('Total Time:', '9 minutes'),
                    _buildStatLine('Signals Prioritized:', '${summary.signalsPrioritized}'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildComparisonColumn('PULSE TIME', summary.pulseTime, AppColors.primary),
                        Text('VS', style: AppTextStyles.micro),
                        _buildComparisonColumn('NORMAL TIME', summary.normalTime, AppColors.textPrimary),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Time Saved: 4 min',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Traffic Impact
              SectionCard(
                title: '[ TRAFFIC IMPACT ]',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildImpactItem('VEHICLES AFFECTED', '${summary.vehiclesAffected}'),
                        _buildImpactItem('SIGNALS ADJUSTED', '${summary.signalsAdjusted}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildImpactItem('ESTIMATED DELAY SAVED', summary.delaySaved),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 5. Action Buttons
              AppButton(
                text: 'START NEW MISSION',
                variant: ButtonVariant.primary,
                icon: Icons.play_arrow,
                onPressed: () => context.go('/mission/setup'),
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'RETURN TO DASHBOARD',
                variant: ButtonVariant.secondary,
                icon: Icons.grid_view,
                onPressed: () => context.go('/dashboard'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label),
          Text(value, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildStatLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label),
          Text(value, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildComparisonColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.micro),
        Text(
          value,
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildImpactItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.micro),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.sectionTitle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
