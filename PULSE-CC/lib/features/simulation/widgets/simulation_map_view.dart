import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/pulse_card.dart';
import '../simulation_controller.dart';

class SimulationMapView extends StatefulWidget {
  final LatLng? ambulancePosition;
  final List<LatLng> corridorWaypoints;
  final String? activeIncidentLocation;
  final SimulationStatus status;

  const SimulationMapView({
    super.key,
    this.ambulancePosition,
    required this.corridorWaypoints,
    this.activeIncidentLocation,
    required this.status,
  });

  @override
  State<SimulationMapView> createState() => _SimulationMapViewState();
}

class _SimulationMapViewState extends State<SimulationMapView> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(SimulationMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ambulancePosition != oldWidget.ambulancePosition &&
        widget.ambulancePosition != null) {
      _mapController.move(widget.ambulancePosition!, _mapController.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PulseCard(
      padding: EdgeInsets.zero,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: widget.corridorWaypoints[0],
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.pulse.ta',
                tileProvider: CancellableNetworkTileProvider(),
                  ),
                  if (widget.status != SimulationStatus.idle)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: widget.corridorWaypoints,
                          color: AppColors.signalGreen,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (widget.ambulancePosition != null)
                        Marker(
                          point: widget.ambulancePosition!,
                          width: 36,
                          height: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: const Icon(Icons.local_hospital, color: Colors.white, size: 18),
                          ),
                        ),
                      if (widget.activeIncidentLocation != null)
                        Marker(
                          point: const LatLng(22.7196, 75.8577),
                          width: 36,
                          height: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: const Icon(Icons.warning, color: Colors.white, size: 18),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'AMB-04',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ),
              if (widget.status == SimulationStatus.running)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: AppColors.liveDot, size: 8),
                        const SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: AppTypography.micro.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
}
