import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/pulse_app_bar.dart';
import '../../../shared/widgets/pulse_bottom_nav.dart';
import '../../../shared/widgets/pulse_card.dart';
import '../../../data/models/emergency_vehicle.dart';
import '../../../data/models/active_mission.dart';
import '../../../data/models/intersection.dart' as imodel;
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/eta_chip.dart';
import '../emergency_controller.dart';
import '../widgets/mission_header_card.dart';
import '../widgets/junction_clearance_column.dart';
import '../../dashboard/dashboard_controller.dart';

class EmergencyMonitorScreen extends ConsumerWidget {
  const EmergencyMonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(emergencyControllerProvider);
    final dashState = ref.watch(dashboardControllerProvider);

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

            if (state.activeMissions.isEmpty)
              PulseCard(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No active missions',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),

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

            // Real-time map with actual vehicle positions and intersection markers
            PulseCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 240,
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: _getMapCenter(state.activeMissions),
                          initialZoom: 14.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.pulse.ta',
                            tileProvider: CancellableNetworkTileProvider(),
                          ),
                          // Route polylines for active missions using intersection coordinates
                          if (primaryMission != null)
                            PolylineLayer(
                              polylines: [
                                _buildRoutePolyline(primaryMission, dashState.intersections),
                              ].where((p) => p.points.length >= 2).toList(),
                            ),
                          // Vehicle markers
                          MarkerLayer(
                            markers: state.activeMissions
                                .where((m) => m.vehicle.currentLat != 0)
                                .map((m) => _buildVehicleMarker(m))
                                .toList(),
                          ),
                          // Intersection markers (emergency mode highlighted)
                          MarkerLayer(
                            markers: dashState.intersections
                                .where((i) => i.signalMode == imodel.SignalMode.emergency)
                                .map((i) => _buildIntersectionMarker(i))
                                .toList(),
                          ),
                        ],
                      ),
                      if (state.activeMissions.isNotEmpty)
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
                                Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${state.activeMissions.length} Active Emergency',
                                  style: AppTypography.micro.copyWith(fontWeight: FontWeight.bold),
                                ),
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

            // Real vehicle intel & junction clearance
            if (primaryMission != null)
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
                          _IntelRow(label: 'Vehicle', value: primaryMission.vehicle.id),
                          const SizedBox(height: 10),
                          _IntelRow(label: 'Driver', value: primaryMission.vehicle.operator.isNotEmpty ? primaryMission.vehicle.operator : 'Unknown'),
                          const SizedBox(height: 10),
                          _IntelRow(label: 'ETA', value: '${primaryMission.vehicle.etaSeconds ~/ 60} min'),
                          const SizedBox(height: 10),
                          _IntelRow(label: 'Distance', value: '${primaryMission.vehicle.distanceKm.toStringAsFixed(1)} km'),
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
                            clearance: _buildClearanceMap(primaryMission, dashState.intersections),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // Alerts section
            if (state.filteredAlerts.isNotEmpty) ...[
              const SectionLabel(label: 'ACTIVE ALERTS'),
              const SizedBox(height: 8),
              ...state.filteredAlerts.take(5).map((alert) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: PulseCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        alert.severity.name == 'high' ? Icons.error : Icons.warning_amber,
                        color: alert.severity.name == 'high' ? AppColors.danger : AppColors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(alert.title, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                            Text(alert.location, style: AppTypography.micro.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.read(emergencyControllerProvider.notifier).clearAlert(alert.id),
                        child: const Text('CLEAR', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              )),
            ],

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
                      onPressed: () {
                        final iid = dashState.intersections.isNotEmpty
                            ? dashState.intersections.first.id
                            : 'INT-001';
                        context.go('/live-map/intersection/$iid');
                      },
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

  LatLng _getMapCenter(List<ActiveMission> missions) {
    if (missions.isNotEmpty) {
      final v = missions.first.vehicle;
      if (v.currentLat != 0 && v.currentLng != 0) {
        return LatLng(v.currentLat, v.currentLng);
      }
    }
    return const LatLng(22.7196, 75.8577);
  }

  Polyline _buildRoutePolyline(ActiveMission mission, List<imodel.Intersection> intersections) {
    final points = <LatLng>[];

    // Prefer road coordinates from OSRM
    if (mission.roadCoordinates.length >= 2) {
      for (final coord in mission.roadCoordinates) {
        if (coord.length >= 2) {
          points.add(LatLng(coord[0], coord[1]));
        }
      }
    } else {
      // Fallback: intersection waypoints
      final intersectionMap = <String, LatLng>{};
      for (final i in intersections) {
        intersectionMap[i.id] = LatLng(i.lat, i.lng);
      }
      if (mission.vehicle.currentLat != 0) {
        points.add(LatLng(mission.vehicle.currentLat, mission.vehicle.currentLng));
      }
      for (final iid in mission.routeIntersections) {
        final coord = intersectionMap[iid];
        if (coord != null) points.add(coord);
      }
    }

    return Polyline(
      points: points,
      color: AppColors.primary,
      strokeWidth: 5,
    );
  }

  Marker _buildVehicleMarker(ActiveMission mission) {
    final v = mission.vehicle;
    Color color;
    IconData icon;
    switch (v.type) {
      case VehicleType.ambulance:
        color = Colors.green;
        icon = Icons.local_hospital;
        break;
      case VehicleType.fire:
        color = Colors.orange;
        icon = Icons.local_fire_department;
        break;
      case VehicleType.police:
        color = Colors.blue;
        icon = Icons.local_police;
        break;
    }
    return Marker(
      point: LatLng(v.currentLat, v.currentLng),
      width: 36,
      height: 36,
      child: Tooltip(
        message: '${v.id}: ${v.etaSeconds ~/ 60} min',
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Marker _buildIntersectionMarker(imodel.Intersection intersection) {
    return Marker(
      point: LatLng(intersection.lat, intersection.lng),
      width: 24,
      height: 24,
      child: Container(
        decoration: BoxDecoration(
          color: intersection.signalMode == imodel.SignalMode.emergency ? Colors.green : Colors.orange,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
        ),
        child: const Icon(Icons.traffic, color: Colors.white, size: 12),
      ),
    );
  }

  Map<String, ClearanceStatus> _buildClearanceMap(
    ActiveMission mission,
    List<imodel.Intersection> intersections,
  ) {
    final intersectionMap = <String, imodel.Intersection>{};
    for (final i in intersections) {
      intersectionMap[i.id] = i;
    }

    final clearance = <String, ClearanceStatus>{};
    for (final iid in mission.routeIntersections.take(5)) {
      final inter = intersectionMap[iid];
      if (inter != null) {
        clearance[inter.name] = inter.signalMode == imodel.SignalMode.emergency
            ? ClearanceStatus.green
            : ClearanceStatus.pending;
      }
    }
    return clearance;
  }
}

class _CompactMissionCard extends StatelessWidget {
  final ActiveMission mission;

  const _CompactMissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                Flexible(
                  child: Text(
                    mission.vehicle.id,
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              mission.vehicle.destinationName.isNotEmpty
                  ? mission.vehicle.destinationName
                  : 'In Progress',
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
