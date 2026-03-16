import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/core/services/location_service.dart';
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
    if (currentMission == null) {
      return _buildNoMissionView(context, currentLatLng);
    }

    // Active mission - show full HUD
    return _buildActiveMissionView(context, ref, currentMission, currentLatLng);
  }

  Widget _buildNoMissionView(BuildContext context, LatLng? currentLatLng) {
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
    // Build route coordinates from mission data
    final routeCoords = <LatLng>[];
    for (final coord in currentMission.routeCoordinates) {
      if (coord.length >= 2) {
        routeCoords.add(LatLng(coord[0], coord[1]));
      }
    }

    // Destination marker
    final destinationLatLng = LatLng(
      currentMission.destinationHospital.lat,
      currentMission.destinationHospital.lng,
    );

    // Determine map center
    LatLng? mapCenter = currentLatLng ?? destinationLatLng;
    if (routeCoords.isNotEmpty) {
      mapCenter = routeCoords.first;
    }

    // Build intersection markers along route
    final intersectionMarkers = <Marker>[];
    if (routeCoords.length > 2) {
      // Show small circle markers at each intermediate route coordinate
      for (int i = 1; i < routeCoords.length - 1; i++) {
        intersectionMarkers.add(
          Marker(
            point: routeCoords[i],
            width: 12,
            height: 12,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        );
      }
    }

    // Build a thicker green route polyline
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
          // Map with custom polylines and intersection markers
          PulseMap(
            center: mapCenter,
            currentPosition: currentLatLng,
            routeCoordinates: const [], // We handle polylines ourselves
            polylines: routePolylines,
            mapMarkers: intersectionMarkers,
            destinationPosition: destinationLatLng,
            destinationLabel: currentMission.destinationHospital.name,
          ),

          // Top Header Layer (HUD)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Container(
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
                 const SizedBox.shrink(),
              ],
            ),
          ),

          // Bottom HUD Layer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  // Mission Stats Card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('MISSION PROGRESS', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('DISTANCE', '${currentMission.distance.toStringAsFixed(1)} km'),
                      _buildStatItem('SIGNALS', '${currentMission.signalsCleared} Cleared'),
                      _buildStatItem('ETA', currentMission.eta),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Destination info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DESTINATION', style: AppTextStyles.micro),
                              const SizedBox(height: 4),
                              Text(
                                currentMission.destinationHospital.name,
                                style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Green Corridor Active',
                                style: AppTextStyles.micro.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.traffic, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // End Mission Button
                  AppButton(
                    text: 'END MISSION',
                    variant: ButtonVariant.emergency,
                    onPressed: () async {
                      await ref.read(missionProvider.notifier).endMission();
                      if (context.mounted) {
                        context.go('/mission/summary');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.micro),
        Text(value, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
      ],
    );
  }
}
