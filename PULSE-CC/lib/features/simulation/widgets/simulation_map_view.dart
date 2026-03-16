import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _mapController;

  @override
  void didUpdateWidget(SimulationMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ambulancePosition != oldWidget.ambulancePosition &&
        widget.ambulancePosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(widget.ambulancePosition!),
      );
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
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: widget.corridorWaypoints[0],
                  zoom: 13.0,
                ),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (controller) => _mapController = controller,
                polylines: widget.status != SimulationStatus.idle
                    ? {
                        Polyline(
                          polylineId: const PolylineId('corridor'),
                          points: widget.corridorWaypoints,
                          color: AppColors.signalGreen,
                          width: 4,
                        ),
                      }
                    : {},
                markers: {
                  if (widget.ambulancePosition != null)
                    Marker(
                      markerId: const MarkerId('ambulance'),
                      position: widget.ambulancePosition!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                    ),
                  if (widget.activeIncidentLocation != null)
                    Marker(
                      markerId: const MarkerId('incident'),
                      position: const LatLng(18.5190, 73.8520), // Mock fixed position for incident
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                    ),
                },
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
