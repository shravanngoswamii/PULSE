import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/features/mission/models/mission_model.dart';
import 'package:pulse_ev/features/mission/providers/mission_provider.dart';
import 'package:pulse_ev/features/mission/screens/mission_setup_screen.dart';
import 'package:pulse_ev/shared/widgets/app_button.dart';
import 'package:pulse_ev/shared/widgets/pulse_map.dart';

class LiveMapScreen extends ConsumerWidget {
  const LiveMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMission = ref.watch(missionProvider);
    final positionAsync = ref.watch(currentPositionProvider);

    // Determine current position as LatLng
    LatLng? currentLatLng;
    final position = positionAsync.valueOrNull;
    if (position != null) {
      currentLatLng = LatLng(position.latitude, position.longitude);
    }

    // No active mission - show plain map view
    if (currentMission == null || currentMission.status != MissionStatus.active) {
      return _buildNoMissionView(context, ref, currentLatLng);
    }

    // Active mission - show full HUD
    return _buildActiveMissionView(context, ref, currentMission, currentLatLng);
  }

  Widget _buildNoMissionView(BuildContext context, WidgetRef ref, LatLng? currentLatLng) {
    final mapCenter = currentLatLng ?? const LatLng(22.7196, 75.8577);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(
          'MAP VIEW',
          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PulseMap(
            center: mapCenter,
            currentPosition: currentLatLng,
          ),
          // LIVE indicator
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('LIVE', style: AppTextStyles.micro.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          // START MISSION button at bottom
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: AppButton(
              text: 'START MISSION',
              variant: ButtonVariant.primary,
              onPressed: () => context.go('/mission/setup'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMissionView(BuildContext context, WidgetRef ref, dynamic currentMission, LatLng? currentLatLng) {
    // Build route coordinates from mission data (backend sends [{lat, lng}] or [[lat, lng]])
    final routeCoords = <LatLng>[];
    for (final coord in currentMission.routeCoordinates) {
      if (coord is List && coord.length >= 2) {
        routeCoords.add(LatLng((coord[0] as num).toDouble(), (coord[1] as num).toDouble()));
      }
    }

    // Destination marker
    final destinationLatLng = LatLng(
      currentMission.destinationHospital.lat,
      currentMission.destinationHospital.lng,
    );

    // Determine map center: prefer current position, then route midpoint
    LatLng? mapCenter = currentLatLng ?? destinationLatLng;
    if (routeCoords.isNotEmpty) {
      mapCenter = routeCoords.first;
    }

    // Build route polyline (no dots - OSRM returns hundreds of points)
    final routePolylines = <Polyline>[];
    if (routeCoords.isNotEmpty) {
      routePolylines.add(
        Polyline(
          points: routeCoords,
          strokeWidth: 6.0,
          color: AppColors.corridorActive,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(
          'ACTIVE MISSION',
          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Map with route polyline
          PulseMap(
            center: mapCenter,
            currentPosition: currentLatLng,
            routeCoordinates: const [],
            polylines: routePolylines,
            destinationPosition: destinationLatLng,
            destinationLabel: currentMission.destinationHospital.name,
          ),

          // Top Header Layer (HUD)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('LIVE', style: AppTextStyles.micro.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // Bottom HUD Layer - compact
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Distance + ETA in one compact row
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.route, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              '${currentMission.distance.toStringAsFixed(1)} km',
                              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.schedule, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              currentMission.eta,
                              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${currentMission.signalsCleared} signals',
                          style: AppTextStyles.micro.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Compact destination card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          child: const Icon(Icons.local_hospital, color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentMission.destinationHospital.name,
                                style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Green Corridor Active',
                                style: AppTextStyles.micro.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // End Mission Button
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(missionProvider.notifier).endMission();
                        if (context.mounted) {
                          context.go('/mission/summary');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emergency,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stop_circle_outlined, size: 18),
                          const SizedBox(width: 6),
                          Text('END MISSION', style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
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
