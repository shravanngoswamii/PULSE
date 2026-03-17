import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/pulse_card.dart';
import '../../../data/models/intersection.dart' as imodel;
import '../dashboard_controller.dart';

class LiveMapPreview extends ConsumerWidget {
  const LiveMapPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    final intersections = state.intersections;
    final missions = state.activeMissions;

    // Signal markers from real intersections
    final signalMarkers = intersections.take(30).map((i) {
      return Marker(
        point: LatLng(i.lat, i.lng),
        width: 20,
        height: 20,
        child: Container(
          decoration: BoxDecoration(
            color: _signalColor(i.signalMode, i.currentPhase),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
          ),
          child: const Icon(Icons.traffic, color: Colors.white, size: 10),
        ),
      );
    }).toList();

    // Vehicle markers from active missions
    final vehicleMarkers = missions.map((m) {
      final v = m.vehicle;
      if (v.currentLat == 0 && v.currentLng == 0) return null;
      return Marker(
        point: LatLng(v.currentLat, v.currentLng),
        width: 28,
        height: 28,
        child: Container(
          decoration: BoxDecoration(
            color: v.type.name == 'ambulance' ? Colors.green
                : v.type.name == 'fire' ? Colors.orange : Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
          ),
          child: Icon(
            v.type.name == 'ambulance' ? Icons.local_hospital
                : v.type.name == 'fire' ? Icons.local_fire_department : Icons.local_police,
            color: Colors.white,
            size: 14,
          ),
        ),
      );
    }).whereType<Marker>().toList();

    final emergencyCount = missions.length;
    final congestedCount = intersections.where((i) => i.congestionLevel == imodel.CongestionLevel.high).length;

    return PulseCard(
      padding: EdgeInsets.zero,
      onTap: () => context.go('/live-map'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 180,
          child: Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(22.7196, 75.8577),
                  initialZoom: 13.0,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.pulse.ta',
                    tileProvider: CancellableNetworkTileProvider(),
                  ),
                  MarkerLayer(markers: signalMarkers),
                  MarkerLayer(markers: vehicleMarkers),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white.withOpacity(0.92),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            emergencyCount > 0
                                ? '$emergencyCount Active Missions'
                                : 'No Active Missions',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                          ),
                          Text(
                            '${intersections.length} Signals  ${congestedCount > 0 ? '/ $congestedCount Congested' : ''}',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.fullscreen, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _signalColor(imodel.SignalMode mode, imodel.SignalPhase phase) {
    if (mode == imodel.SignalMode.emergency) return Colors.green;
    switch (phase) {
      case imodel.SignalPhase.green:
        return Colors.green;
      case imodel.SignalPhase.red:
        return Colors.red;
      case imodel.SignalPhase.amber:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
