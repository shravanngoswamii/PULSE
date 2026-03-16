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
                    const SectionLabel(label: 'SYSTEM STATUS'),
                    SystemStatusCard(status: state.systemStatus),
                    const SizedBox(height: 20),
                    const SectionLabel(label: 'LIVE MAP INTELLIGENCE'),
                    const LiveMapPreview(),
                    const SizedBox(height: 20),
                    const SectionLabel(label: 'ACTIVE MISSIONS'),
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
                      label: 'SIMULATION CONTROL',
                      icon: Icons.bar_chart,
                      backgroundColor: AppColors.surface,
                      textColor: AppColors.textPrimary,
                      showBorder: true,
                      onTap: () => context.go('/simulation'),
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
