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
      body: dashboardAsync.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (err, stack) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(dashboardProvider),
        ),
        data: (data) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(gradient: AppColors.darkGradient),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 10),
                                Text('PULSE', style: AppTextStyles.sectionTitle.copyWith(color: Colors.white, letterSpacing: 2)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                  const SizedBox(width: 5),
                                  Text('Online', style: AppTextStyles.micro.copyWith(color: Colors.white70, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data.vehicleName,
                                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(data.station, style: AppTextStyles.micro.copyWith(color: Colors.white54)),
                                  ],
                                ),
                              ),
                              StatusBadge(status: data.vehicleStatus),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -12),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasActiveMission)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GestureDetector(
                              onTap: () => context.go('/mission/active'),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: AppShadows.glow,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.radio_button_checked, color: Colors.white, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Active Mission',
                                            style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Tap to view live tracking',
                                            style: AppTextStyles.micro.copyWith(color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        GestureDetector(
                          onTap: () => context.go('/mission/active'),
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: AppShadows.elevated,
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
                                        center: latLng ?? const LatLng(22.8206, 75.9427),
                                        currentPosition: latLng,
                                        zoom: 14.0,
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: AppShadows.card,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.fullscreen_rounded, size: 16, color: AppColors.primary),
                                        const SizedBox(width: 5),
                                        Text('View Map', style: AppTextStyles.micro.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context.go('/mission/setup'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: AppShadows.glow,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'New Mission',
                                        style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context.go('/mission/active'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: AppShadows.card,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceLight,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.map_rounded, color: AppColors.primary, size: 22),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'View Map',
                                        style: AppTextStyles.label.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        if (data.recentMissions.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'RECENT MISSIONS',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, letterSpacing: 1),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${data.recentMissions.length}',
                                  style: AppTextStyles.micro.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...data.recentMissions.map((mission) {
                            final isCompleted = mission.status == 'completed';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: AppShadows.card,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? AppColors.primary.withValues(alpha: 0.1)
                                            : Colors.orange.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isCompleted ? Icons.check_circle_rounded : Icons.local_hospital_rounded,
                                        color: isCompleted ? AppColors.primary : Colors.orange,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mission.to,
                                            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              if (mission.durationMinutes > 0) ...[
                                                Icon(Icons.timer_outlined, size: 12, color: AppColors.textSecondary),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '${mission.durationMinutes} min',
                                                  style: AppTextStyles.micro.copyWith(color: AppColors.textSecondary),
                                                ),
                                                const SizedBox(width: 10),
                                              ],
                                              Icon(
                                                isCompleted ? Icons.check : Icons.pending_outlined,
                                                size: 12,
                                                color: isCompleted ? AppColors.primary : Colors.orange,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                isCompleted ? 'Completed' : (mission.status ?? 'Unknown'),
                                                style: AppTextStyles.micro.copyWith(
                                                  color: isCompleted ? AppColors.primary : Colors.orange,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
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
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -2),
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
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
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.rocket_launch_outlined), activeIcon: Icon(Icons.rocket_launch_rounded), label: 'Mission'),
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map_rounded), label: 'Map'),
          ],
        ),
      ),
    );
  }
}
