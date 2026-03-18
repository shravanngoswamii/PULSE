import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/features/dashboard/models/dashboard_model.dart';
import 'package:pulse_ev/features/dashboard/providers/dashboard_provider.dart';
import 'package:pulse_ev/features/mission/screens/mission_setup_screen.dart';
import 'package:pulse_ev/features/mission/models/mission_model.dart';
import 'package:pulse_ev/features/mission/providers/mission_provider.dart';
import 'package:pulse_ev/shared/widgets/pulse_map.dart';
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
                        // Dispatch notifications now handled by global DispatchOverlay
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
                              child: GestureDetector(
                                onTap: () => _showMissionDetail(context, mission),
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
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          mission.timeAgo,
                                          style: AppTextStyles.micro.copyWith(color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(height: 2),
                                        Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondary),
                                      ],
                                    ),
                                  ],
                                ),
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

  void _showMissionDetail(BuildContext context, RecentMission mission) {
    final isCompleted = mission.status == 'completed';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: isCompleted ? AppColors.primaryGradient : null,
                    color: isCompleted ? null : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle_rounded : Icons.pending_rounded,
                    color: Colors.white, size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.to,
                        style: AppTextStyles.sectionTitle.copyWith(fontSize: 17),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCompleted ? 'Mission Completed' : (mission.status ?? 'Unknown'),
                        style: AppTextStyles.micro.copyWith(
                          color: isCompleted ? AppColors.primary : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Stats row
            Row(
              children: [
                _buildStatChip(Icons.route_rounded, '${(mission.distanceKm ?? 0).toStringAsFixed(1)} km', 'Distance'),
                const SizedBox(width: 10),
                _buildStatChip(Icons.timer_outlined, '${mission.durationMinutes} min', 'Duration'),
                const SizedBox(width: 10),
                _buildStatChip(Icons.traffic_rounded, '${mission.signalsCleared}', 'Signals'),
              ],
            ),
            const SizedBox(height: 16),
            // Details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  if (mission.incidentType != null)
                    _buildDetailRow('Incident', mission.incidentType!),
                  if (mission.priority != null)
                    _buildDetailRow('Priority', mission.priority!),
                  _buildDetailRow('From', mission.from),
                  _buildDetailRow('To', mission.to),
                  if (mission.startedAt != null)
                    _buildDetailRow('Started', _formatDateTime(mission.startedAt!)),
                  if (mission.completedAt != null)
                    _buildDetailRow('Completed', _formatDateTime(mission.completedAt!)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
            Text(label, style: AppTextStyles.micro),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.micro.copyWith(color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day}/${dt.month}/${dt.year} $h:$min $ampm';
    } catch (_) {
      return isoString;
    }
  }
}
