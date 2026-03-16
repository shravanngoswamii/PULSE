import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/features/mission/providers/mission_provider.dart';
import 'package:pulse_ev/features/auth/providers/user_provider.dart';
import 'package:pulse_ev/shared/widgets/app_button.dart';
import 'package:pulse_ev/shared/widgets/section_card.dart';
import 'package:pulse_ev/shared/widgets/pulse_map.dart';

class MissionSummaryScreen extends ConsumerWidget {
  const MissionSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mission = ref.watch(missionProvider);
    final user = ref.watch(currentUserProvider);

    // Build route coordinates for map display
    final routeCoords = <LatLng>[];
    if (mission != null) {
      for (final coord in mission.routeCoordinates) {
        if (coord.length >= 2) {
          routeCoords.add(LatLng(coord[0], coord[1]));
        }
      }
    }

    LatLng? destinationLatLng;
    if (mission != null) {
      destinationLatLng = LatLng(
        mission.destinationHospital.lat,
        mission.destinationHospital.lng,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(
          'MISSION SUMMARY',
          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // 1. Mission Completed Banner
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MISSION COMPLETED',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Vehicle:', user?.vehicleId ?? 'N/A'),
                  _buildInfoRow('Driver:', user?.name ?? 'N/A'),
                  _buildInfoRow('Incident:', mission?.incidentType ?? 'N/A'),
                  _buildInfoRow('Priority:', mission?.priorityLevel ?? 'N/A'),
                  _buildInfoRow('Destination:', mission?.destinationHospital.name ?? 'N/A'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Route Summary
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ROUTE SUMMARY', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: PulseMap(
                    center: routeCoords.isNotEmpty ? routeCoords.first : destinationLatLng,
                    routeCoordinates: routeCoords,
                    destinationPosition: destinationLatLng,
                    destinationLabel: mission?.destinationHospital.name,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Mission Statistics
            SectionCard(
              title: 'MISSION STATISTICS',
              child: Column(
                children: [
                  _buildStatLine('Distance:', '${mission?.distance.toStringAsFixed(1) ?? "0.0"} km'),
                  _buildStatLine('ETA:', mission?.eta ?? 'N/A'),
                  _buildStatLine('Signals Cleared:', '${mission?.signalsCleared ?? 0}'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 4. Action Buttons
            AppButton(
              text: 'START NEW MISSION',
              variant: ButtonVariant.primary,
              icon: Icons.play_arrow,
              onPressed: () => context.go('/mission/setup'),
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'RETURN TO DASHBOARD',
              variant: ButtonVariant.secondary,
              icon: Icons.grid_view,
              onPressed: () => context.go('/dashboard'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label),
          Text(value, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildStatLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label),
          Text(value, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
