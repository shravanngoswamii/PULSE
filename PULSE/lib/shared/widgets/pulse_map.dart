import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:pulse_ev/config/app_theme.dart';

class PulseMap extends StatelessWidget {
  final List<String> markers;
  final LatLng? center;
  final double zoom;
  final List<Marker> mapMarkers;
  final List<Polyline> polylines;
  final LatLng? currentPosition;
  final List<LatLng> routeCoordinates;
  final LatLng? destinationPosition;
  final String? destinationLabel;
  final void Function(TapPosition, LatLng)? onTap;
  final List<Marker> extraMarkers;

  const PulseMap({
    super.key,
    this.markers = const [],
    this.center,
    this.zoom = 14.0,
    this.mapMarkers = const [],
    this.polylines = const [],
    this.currentPosition,
    this.routeCoordinates = const [],
    this.destinationPosition,
    this.destinationLabel,
    this.onTap,
    this.extraMarkers = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Determine map center priority: currentPosition > center > default
    final mapCenter = currentPosition ?? center ?? const LatLng(22.7196, 75.8577);

    // Build all markers
    final allMarkers = <Marker>[];

    // Add user-supplied map markers
    if (mapMarkers.isNotEmpty) {
      allMarkers.addAll(mapMarkers);
    } else if (markers.isNotEmpty) {
      allMarkers.addAll(_buildDefaultMarkers(mapCenter));
    }

    // Add current position blue dot
    if (currentPosition != null) {
      allMarkers.add(
        Marker(
          point: currentPosition!,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Add destination marker
    if (destinationPosition != null) {
      allMarkers.add(
        Marker(
          point: destinationPosition!,
          width: 120,
          height: 50,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (destinationLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
                  ),
                  child: Text(
                    destinationLabel!,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const Icon(Icons.local_hospital, color: Colors.red, size: 28),
            ],
          ),
        ),
      );
    }

    // Merge extra markers (e.g. destination pin from DestinationPickerScreen)
    if (extraMarkers.isNotEmpty) {
      allMarkers.addAll(extraMarkers);
    }

    // Build polylines
    final allPolylines = <Polyline>[...polylines];
    if (routeCoordinates.isNotEmpty) {
      allPolylines.add(
        Polyline(
          points: routeCoordinates,
          strokeWidth: 4.0,
          color: AppColors.primary,
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: mapCenter,
        initialZoom: zoom,
        onTap: onTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.pulse.ev',
          tileProvider: CancellableNetworkTileProvider(),
        ),
        if (allPolylines.isNotEmpty)
          PolylineLayer(polylines: allPolylines),
        if (allMarkers.isNotEmpty)
          MarkerLayer(markers: allMarkers),
      ],
    );
  }

  List<Marker> _buildDefaultMarkers(LatLng center) {
    if (markers.isEmpty) return [];

    final List<Marker> result = [];
    final offsets = [
      const LatLng(0.0, 0.0),
      const LatLng(0.005, 0.003),
      const LatLng(-0.003, 0.006),
      const LatLng(0.007, -0.004),
    ];

    for (int i = 0; i < markers.length; i++) {
      final offset = offsets[i % offsets.length];
      result.add(
        Marker(
          point: LatLng(center.latitude + offset.latitude, center.longitude + offset.longitude),
          width: 120,
          height: 50,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 3),
                  ],
                ),
                child: Text(
                  markers[i],
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              Icon(
                _getIcon(markers[i]),
                color: _getColor(markers[i]),
                size: 28,
              ),
            ],
          ),
        ),
      );
    }

    return result;
  }

  static IconData _getIcon(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('ambulance') || lower.contains('hospital')) return Icons.local_hospital;
    if (lower.contains('fire')) return Icons.local_fire_department;
    if (lower.contains('police')) return Icons.local_police;
    if (lower.contains('intersection') || lower.contains('signal')) return Icons.traffic;
    return Icons.location_on;
  }

  static Color _getColor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('ambulance')) return AppColors.primary;
    if (lower.contains('hospital')) return Colors.red;
    if (lower.contains('fire')) return Colors.orange;
    if (lower.contains('police')) return Colors.blue;
    if (lower.contains('intersection') || lower.contains('signal')) return Colors.amber;
    return AppColors.emergency;
  }
}
