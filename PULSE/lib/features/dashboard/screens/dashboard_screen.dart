import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/features/dashboard/providers/dashboard_provider.dart';
import 'package:pulse_ev/features/mission/screens/mission_setup_screen.dart';
import 'package:pulse_ev/features/mission/models/mission_model.dart';
import 'package:pulse_ev/features/mission/providers/mission_provider.dart';
import 'package:pulse_ev/shared/widgets/pulse_map.dart';
import 'package:pulse_ev/shared/widgets/section_card.dart';
import 'package:pulse_ev/shared/widgets/status_badge.dart';
import 'package:pulse_ev/shared/widgets/loading_indicator.dart';
import 'package:pulse_ev/shared/widgets/error_view.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final currentMission = ref.watch(missionProvider);
    final hasActiveMission = currentMission != null && currentMission.status == MissionStatus.active;
    final positionAsync = ref.watch(currentPositionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PULSE',
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (err, stack) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(dashboardProvider),
        ),
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Mission Banner
              if (hasActiveMission)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => context.go('/mission/active'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.radio_button_checked, color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Mission in Progress',
                                  style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Tap to view',
                                  style: AppTextStyles.micro.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),

              // Compact Vehicle Status
              SectionCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.vehicleName,
                            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Text(data.station, style: AppTextStyles.micro),
                        ],
                      ),
                    ),
                    StatusBadge(status: data.vehicleStatus),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Map Preview Card
              GestureDetector(
                onTap: () => context.go('/mission/active'),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        offset: const Offset(0, 2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      positionAsync.when(
                        loading: () => Container(
                          color: AppColors.border,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        error: (_, __) => Container(
                          color: AppColors.border,
                          child: const Center(child: Icon(Icons.map, color: AppColors.textSecondary)),
                        ),
                        data: (pos) {
                          LatLng? latLng;
                          if (pos != null) {
                            latLng = LatLng(pos.latitude, pos.longitude);
                          }
                          return AbsorbPointer(
                            child: PulseMap(
                              center: latLng ?? const LatLng(22.7196, 75.8577),
                              currentPosition: latLng,
                              zoom: 14.0,
                            ),
                          );
                        },
                      ),
                      // "View Map" overlay
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fullscreen, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text('View Map', style: AppTextStyles.micro.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Two action buttons side by side
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.go('/mission/setup'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
                            const SizedBox(height: 6),
                            Text(
                              'New Mission',
                              style: AppTextStyles.micro.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.go('/mission/active'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.map_outlined, color: AppColors.primary, size: 24),
                            const SizedBox(height: 6),
                            Text(
                              'View Map',
                              style: AppTextStyles.micro.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Recent Missions
              if (data.recentMissions.isNotEmpty) ...[
                Text(
                  'RECENT MISSIONS',
                  style: AppTextStyles.micro.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                ...data.recentMissions.map((mission) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.local_hospital, color: AppColors.primary, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mission.to,
                                  style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  mission.durationMinutes > 0 ? '${mission.durationMinutes} min' : 'Completed',
                                  style: AppTextStyles.micro,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            mission.timeAgo,
                            style: AppTextStyles.micro.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              if (hasActiveMission) {
                context.go('/mission/active');
              } else {
                context.push('/mission/setup');
              }
              break;
            case 2:
              context.go('/mission/active');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.rocket_launch_outlined), activeIcon: Icon(Icons.rocket_launch), label: 'Mission'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Map'),
        ],
      ),
    );
  }
}
