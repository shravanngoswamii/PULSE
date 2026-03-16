import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/features/traffic/providers/traffic_provider.dart';
import 'package:pulse_ev/shared/widgets/app_button.dart';
import 'package:pulse_ev/shared/widgets/section_card.dart';
import 'package:pulse_ev/shared/widgets/pulse_map.dart';
import 'package:pulse_ev/shared/widgets/loading_indicator.dart';
import 'package:pulse_ev/shared/widgets/error_view.dart';

class TrafficIntelligenceScreen extends ConsumerWidget {
  const TrafficIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trafficAsync = ref.watch(trafficDataProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'TRAFFIC INTELLIGENCE',
          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
        centerTitle: true,
      ),
      body: trafficAsync.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(trafficDataProvider),
        ),
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Heatmap
              Text('TRAFFIC HEATMAP', style: AppTextStyles.micro.copyWith(letterSpacing: 1)),
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
                    // Overlays to simulate heatmap segments
                    Positioned(
                      left: 10,
                      top: 80,
                      child: Container(
                        width: 150,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 170,
                      top: 80,
                      child: Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 280,
                      top: 80,
                      child: Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 220,
                      top: 100,
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Traffic Statistics
              Text('TRAFFIC STATISTICS', style: AppTextStyles.micro.copyWith(letterSpacing: 1)),
              const SizedBox(height: 8),
              SectionCard(
                child: Column(
                  children: [
                    _buildStatRow('Traffic Density:', data.trafficDensity, AppColors.textPrimary),
                    _buildStatRow('Blocked Roads:', '${data.blockedRoads}', AppColors.emergency),
                    _buildStatRow('Avg Signal Time:', '${data.avgSignalTime} sec', AppColors.textPrimary),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Incident Alerts
              Text('INCIDENT ALERTS', style: AppTextStyles.micro.copyWith(letterSpacing: 1)),
              const SizedBox(height: 8),
              Column(
                children: data.incidents.map((incident) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: SectionCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.emergency.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.warning_amber_rounded, color: AppColors.emergency, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${incident.title} – ${incident.location}', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
                                Text('Distance: ${incident.distance}', style: AppTextStyles.micro),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // 4. Alternate Routes
              Text('ALTERNATE ROUTES', style: AppTextStyles.micro.copyWith(letterSpacing: 1)),
              const SizedBox(height: 8),
              SectionCard(
                child: Row(
                  children: data.alternateRoutes.asMap().entries.map((entry) {
                    final route = entry.value;
                    final isFirst = entry.key == 0;
                    return Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: isFirst ? const Border(right: BorderSide(color: AppColors.border)) : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${route.name} – ${route.description}', style: AppTextStyles.micro),
                            const SizedBox(height: 4),
                            Text(
                              'ETA: ${route.eta}',
                              style: AppTextStyles.label.copyWith(
                                color: isFirst ? AppColors.primary : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),

              // 5. Return Button
              AppButton(
                text: 'RETURN TO NAVIGATION',
                variant: ButtonVariant.primary,
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label),
          Text(
            value,
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
