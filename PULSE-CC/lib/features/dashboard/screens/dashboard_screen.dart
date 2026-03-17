import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/pulse_app_bar.dart';
import '../../../shared/widgets/pulse_bottom_nav.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../shared/widgets/status_badge.dart';
import '../dashboard_controller.dart';
import '../widgets/system_status_card.dart';
import '../widgets/live_map_preview.dart';
import '../widgets/active_mission_tile.dart';
import '../widgets/intersection_quick_control.dart';
import '../widgets/traffic_analytics_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PulseAppBar(
        title: 'PULSE Traffic Command',
        subtitle: 'Central Traffic Command',
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: StatusBadge(type: BadgeType.live),
          ),
        ],
      ),
      body: state.isLoading && state.activeMissions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(dashboardControllerProvider.notifier).refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Approaching vehicle alert banners
                    ...state.approachingAlerts.map((alert) => _ApproachingAlertBanner(
                      alert: alert,
                      onDismiss: () => ref.read(dashboardControllerProvider.notifier).dismissAlert(alert),
                    )),

                    const SectionLabel(label: 'SYSTEM STATUS'),
                    SystemStatusCard(status: state.systemStatus),
                    const SizedBox(height: 20),
                    const SectionLabel(label: 'LIVE MAP INTELLIGENCE'),
                    const LiveMapPreview(),
                    const SizedBox(height: 20),
                    SectionLabel(
                      label: 'ACTIVE MISSIONS',
                      trailing: state.activeMissions.isNotEmpty
                          ? Text(
                              '${state.activeMissions.length}',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    if (state.activeMissions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No active missions',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ...state.activeMissions.map((mission) => ActiveMissionTile(mission: mission)),
                    const SizedBox(height: 20),
                    if (state.intersections.isNotEmpty) ...[
                      const SectionLabel(label: 'INTERSECTION CONTROL'),
                      IntersectionQuickControl(
                        intersection: state.intersections.first,
                        onForce: (phase) => ref.read(dashboardControllerProvider.notifier).forceSignal(state.intersections.first.id, phase),
                        onRestore: () => ref.read(dashboardControllerProvider.notifier).restoreAutoControl(state.intersections.first.id),
                      ),
                      const SizedBox(height: 20),
                    ],
                    const SectionLabel(label: 'TRAFFIC ANALYTICS'),
                    const TrafficAnalyticsCard(),
                    const SizedBox(height: 20),
                    _StackedButton(
                      label: 'OPEN LIVE TRAFFIC MAP',
                      icon: Icons.map,
                      backgroundColor: AppColors.primary,
                      textColor: Colors.white,
                      onTap: () => context.go('/live-map'),
                    ),
                    const SizedBox(height: 12),
                    _StackedButton(
                      label: 'EMERGENCY MONITOR',
                      icon: Icons.warning_amber,
                      backgroundColor: AppColors.surface,
                      textColor: AppColors.textPrimary,
                      showBorder: true,
                      onTap: () => context.go('/emergencies'),
                    ),
                    const SizedBox(height: 12),
                    _StackedButton(
                      label: 'SYSTEM SETTINGS',
                      icon: Icons.settings_outlined,
                      backgroundColor: AppColors.surface,
                      textColor: AppColors.textPrimary,
                      showBorder: true,
                      onTap: () => context.push('/settings'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const PulseBottomNav(currentIndex: 0),
    );
  }
}

/// Banner showing when a driver is approaching an intersection near the operator.
class _ApproachingAlertBanner extends StatelessWidget {
  final ApproachingVehicleAlert alert;
  final VoidCallback onDismiss;

  const _ApproachingAlertBanner({required this.alert, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMERGENCY VEHICLE APPROACHING',
                  style: AppTypography.micro.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.message,
                  style: AppTypography.bodySmall.copyWith(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${alert.vehicleId} → ${alert.intersectionName}',
                  style: AppTypography.micro.copyWith(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

class _StackedButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final bool showBorder;
  final VoidCallback onTap;

  const _StackedButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.showBorder = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: showBorder ? const BorderSide(color: AppColors.border) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(color: textColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
