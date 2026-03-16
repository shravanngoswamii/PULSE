import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/pulse_app_bar.dart';
import '../../../shared/widgets/pulse_bottom_nav.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../data/models/traffic_alert.dart';
import '../emergency_controller.dart';
import '../widgets/alert_feed_tile.dart';
import '../widgets/incident_detail_card.dart';
import '../widgets/alert_filter_tabs.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(emergencyControllerProvider);
    final controller = ref.read(emergencyControllerProvider.notifier);

    final alerts = state.filteredAlerts;
    final highSeverityAlerts = alerts.where((a) => a.severity == Severity.high).toList();
    final highSeverityIncident = highSeverityAlerts.isNotEmpty ? highSeverityAlerts.first : (alerts.isNotEmpty ? alerts.first : null);

    return LoadingOverlay(
      isLoading: state.isLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const PulseAppBar(
          title: 'ALERTS & INCIDENTS',
          subtitle: 'City Traffic Alert Center',
        ),
        body: Column(
          children: [
          AlertFilterTabs(
            activeFilter: state.activeFilter,
            onFilterChanged: controller.setFilter,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const SectionLabel(
                    label: 'ACTIVE FEED',
                    trailing: StatusBadge(type: BadgeType.live),
                  ),
                  const SizedBox(height: 8),

                  if (alerts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(child: Text('No active alerts found')),
                    )
                  else
                    ...alerts.take(3).map((alert) => AlertFeedTile(alert: alert)),

                  const SizedBox(height: 20),
                  const SectionLabel(label: 'STATUS ANALYSIS'),
                  const SizedBox(height: 8),

                  if (highSeverityIncident != null)
                    IncidentDetailCard(alert: highSeverityIncident),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: highSeverityIncident != null ? () => controller.clearAlert(highSeverityIncident.id) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'CLEAR INCIDENT',
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => context.go('/live-map/intersection/INT-001'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.traffic, color: AppColors.textPrimary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'OPEN INTERSECTION CONTROL',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const SectionLabel(
                    label: 'EVENT LOGS',
                    trailing: Icon(Icons.history, color: AppColors.textHint, size: 18),
                  ),

                  _LogEntry(
                    time: '10:35 AM',
                    message: 'Emergency vehicle dispatched',
                    dotColor: AppColors.signalGreen,
                    isFirst: true,
                  ),
                  _LogEntry(
                    time: '10:33 AM',
                    message: 'Accident created at MG Road',
                    dotColor: AppColors.danger,
                  ),
                  _LogEntry(
                    time: '10:32 AM',
                    message: 'Traffic density increased (Junction A4)',
                    dotColor: AppColors.textHint,
                    isLast: true,
                    isDimmed: true,
                  ),

                  const SizedBox(height: 24),
                  SizedBox(height: 64 + MediaQuery.paddingOf(context).bottom),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const PulseBottomNav(currentIndex: 3),
    ),);
  }
}

class _LogEntry extends StatelessWidget {
  final String time;
  final String message;
  final Color dotColor;
  final bool isFirst;
  final bool isLast;
  final bool isDimmed;

  const _LogEntry({
    required this.time,
    required this.message,
    required this.dotColor,
    this.isFirst = false,
    this.isLast = false,
    this.isDimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 16,
            child: Column(
              children: [
                if (!isFirst) Expanded(child: Container(width: 1, color: AppColors.border)),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                if (!isLast) Expanded(child: Container(width: 1, color: AppColors.border)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDimmed ? AppColors.textSecondary : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
