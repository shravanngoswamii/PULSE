import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/pulse_app_bar.dart';
import '../../../shared/widgets/pulse_bottom_nav.dart';
import '../../../shared/widgets/pulse_card.dart';
import '../../../data/models/emergency_vehicle.dart';
import '../../../data/models/active_mission.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/eta_chip.dart';
import '../emergency_controller.dart';
import '../widgets/mission_header_card.dart';
import '../widgets/junction_clearance_column.dart';
import '../widgets/event_timeline.dart';

class EmergencyMonitorScreen extends ConsumerWidget {
  const EmergencyMonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(emergencyControllerProvider);
    final controller = ref.read(emergencyControllerProvider.notifier);

    final primaryMission = state.primaryMission;

    return LoadingOverlay(
      isLoading: state.isLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const PulseAppBar(
          title: 'EMERGENCY EVENT MONITOR',
          subtitle: 'City Emergency Operations',
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const SectionLabel(
              label: 'ACTIVE MISSIONS',
              trailing: StatusBadge(type: BadgeType.live),
            ),
            const SizedBox(height: 12),

            if (primaryMission != null)
              MissionHeaderCard(mission: primaryMission),

            const SizedBox(height: 8),

            if (state.activeMissions.length > 1)
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.activeMissions.length - 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final mission = state.activeMissions[index + 1];
                    return _CompactMissionCard(mission: mission);
                  },
                ),
              ),

            const SizedBox(height: 20),

            PulseCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 240,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(18.5204, 73.8567),
                          zoom: 14.0,
                        ),
                        markers: {
                          const Marker(
                            markerId: MarkerId('ambulance_a12'),
                            position: LatLng(18.5204, 73.8567),
                            infoWindow: InfoWindow(title: 'A-12: 5 min'),
                          ),
                          Marker(
                            markerId: const MarkerId('incident'),
                            position: const LatLng(18.5250, 73.8600),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                          ),
                        },
                        polylines: {
                          const Polyline(
                            polylineId: PolylineId('route_a12'),
                            color: AppColors.primary,
                            width: 5,
                            points: [
                              LatLng(18.5150, 73.8500),
                              LatLng(18.5204, 73.8567),
                              LatLng(18.5250, 73.8600),
                            ],
                          ),
                        },
                        zoomControlsEnabled: false,
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Column(
                          children: [
                            _MapActionBtn(icon: Icons.add, onTap: () {}),
                            const SizedBox(height: 8),
                            _MapActionBtn(icon: Icons.remove, onTap: () {}),
                            const SizedBox(height: 12),
                            _MapActionBtn(icon: Icons.my_location, onTap: () {}),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 14),
                              const SizedBox(width: 4),
                              Text('Incident Detected', style: AppTypography.micro.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PulseCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VEHICLE INTEL',
                          style: AppTypography.micro.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _IntelRow(label: 'Operator', value: 'S. Jameson'),
                        const SizedBox(height: 10),
                        _IntelRow(label: 'Distance Remaining', value: '3.8 km'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PulseCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'JUNCTION CLEARANCE',
                          style: AppTypography.micro.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        JunctionClearanceColumn(
                          clearance: {
                            'MG Road': ClearanceStatus.green,
                            'C. Square': ClearanceStatus.green,
                            'Market': ClearanceStatus.pending,
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const SectionLabel(label: 'EVENT TIMELINE'),
            const SizedBox(height: 8),
            EventTimeline(
              events: [
                MissionEvent(timestamp: DateTime.now(), type: EventType.info, message: 'Mission Started'),
                MissionEvent(timestamp: DateTime.now(), type: EventType.info, message: 'Signal Priority Activated'),
                MissionEvent(timestamp: DateTime.now(), type: EventType.cleared, message: 'MG Road Junction Cleared'),
                MissionEvent(
                  timestamp: DateTime.now(),
                  type: EventType.warning,
                  message: 'Downtown Congestion Alert',
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => context.go('/live-map'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'VIEW ROUTE',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.go('/live-map/intersection/INT-001'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        'INTERSECTIONS',
                        style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            SizedBox(height: 64 + MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
      bottomNavigationBar: const PulseBottomNav(currentIndex: 3),
    ),);
  }
}

class _CompactMissionCard extends StatelessWidget {
  final ActiveMission mission;

  const _CompactMissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      child: PulseCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getIcon(), size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${_getPrefix()}-${mission.vehicle.id}',
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${mission.vehicle.originName} → ${mission.vehicle.destinationName}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            EtaChip(etaMinutes: mission.vehicle.etaSeconds ~/ 60),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (mission.vehicle.type) {
      case VehicleType.ambulance:
        return Icons.local_hospital;
      case VehicleType.fire:
        return Icons.fire_truck;
      case VehicleType.police:
        return Icons.shield;
    }
  }

  String _getPrefix() {
    switch (mission.vehicle.type) {
      case VehicleType.ambulance:
        return 'A';
      case VehicleType.fire:
        return 'F';
      case VehicleType.police:
        return 'P';
    }
  }
}

class _IntelRow extends StatelessWidget {
  final String label;
  final String value;

  const _IntelRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MapActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }
}
