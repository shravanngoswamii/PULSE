import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/pulse_bottom_nav.dart';
import '../live_map_controller.dart';
import '../widgets/corridor_overlay.dart';
import '../widgets/vehicle_marker.dart';
import '../widgets/signal_marker.dart';
import '../widgets/intersection_info_sheet.dart';
import '../widgets/map_layer_toggles.dart';

class LiveMapScreen extends ConsumerStatefulWidget {
  const LiveMapScreen({super.key});

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveMapControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveMapControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Layer 1 - OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(22.7196, 75.8577),
              initialZoom: 14.0,
              onTap: (_, __) => ref.read(liveMapControllerProvider.notifier).clearSelection(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pulse.ta',
                tileProvider: CancellableNetworkTileProvider(),
              ),
              // Corridor polylines
              if (state.showEmergencyVehicles)
                CorridorOverlay.getCorridorLayer(state.activeMissions),
              // Vehicle markers
              if (state.showEmergencyVehicles)
                MarkerLayer(
                  markers: state.activeMissions
                      .map((mission) => VehicleMarker.create(
                            mission,
                            etaMinutes: mission.vehicle.etaSeconds ~/ 60,
                          ))
                      .toList(),
                ),
              // Signal markers
              if (state.showSignals)
                MarkerLayer(
                  markers: state.intersections
                      .map((intersection) => SignalMarker.create(
                            intersection,
                            onTap: () => ref
                                .read(liveMapControllerProvider.notifier)
                                .selectIntersection(intersection),
                          ))
                      .toList(),
                ),
            ],
          ),

          // Layer 2 - Top Bar
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => context.go('/dashboard'),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LIVE TRAFFIC MAP', style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                        Text('CENTRAL TRAFFIC NETWORK', style: AppTypography.micro.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: AppColors.textPrimary),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
            ),
          ),

          // Layer 3 - Zoom Controls
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 80,
            child: Column(
              children: [
                _ZoomButton(
                  icon: Icons.add,
                  onTap: () {
                    final zoom = _mapController.camera.zoom + 1;
                    _mapController.move(_mapController.camera.center, zoom);
                  },
                ),
                const SizedBox(height: 8),
                _ZoomButton(
                  icon: Icons.remove,
                  onTap: () {
                    final zoom = _mapController.camera.zoom - 1;
                    _mapController.move(_mapController.camera.center, zoom);
                  },
                ),
              ],
            ),
          ),

          // Layer 7 & 8 - Bottom Persistent Controls
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.selectedIntersection == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: MapLayerToggles(
                      showSignals: state.showSignals,
                      showVehicles: state.showEmergencyVehicles,
                      onToggleSignals: () => ref.read(liveMapControllerProvider.notifier).toggleSignalLayer(),
                      onToggleVehicles: () => ref.read(liveMapControllerProvider.notifier).toggleVehicleLayer(),
                    ),
                  ),
                if (state.selectedIntersection != null)
                  IntersectionInfoSheet(
                    intersection: state.selectedIntersection!,
                    onOpenControl: () => context.go('/live-map/intersection/${state.selectedIntersection!.id}'),
                    onClose: () => ref.read(liveMapControllerProvider.notifier).clearSelection(),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const PulseBottomNav(currentIndex: 1),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          child: Icon(icon, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
