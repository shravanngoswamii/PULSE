import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/active_mission.dart';
import '../../../data/models/intersection.dart';

class CorridorOverlay {
  /// Build corridor polylines from active missions.
  /// Prefers OSRM road coordinates if available, otherwise falls back to
  /// intersection waypoints along the route path.
  static PolylineLayer getCorridorLayer(
    List<ActiveMission> missions, {
    List<Intersection> intersections = const [],
  }) {
    final List<Polyline> polylines = [];

    // Build lookup from intersection ID -> LatLng
    final intersectionMap = <String, LatLng>{};
    for (final i in intersections) {
      intersectionMap[i.id] = LatLng(i.lat, i.lng);
    }

    for (final mission in missions) {
      final points = <LatLng>[];

      // Prefer road coordinates from OSRM (smooth road-following path)
      if (mission.roadCoordinates.length >= 2) {
        for (final coord in mission.roadCoordinates) {
          if (coord.length >= 2) {
            points.add(LatLng(coord[0], coord[1]));
          }
        }
      } else {
        // Fallback: connect vehicle position + intersection waypoints
        if (mission.vehicle.currentLat != 0 && mission.vehicle.currentLng != 0) {
          points.add(LatLng(mission.vehicle.currentLat, mission.vehicle.currentLng));
        }
        for (final iid in mission.routeIntersections) {
          final coord = intersectionMap[iid];
          if (coord != null) {
            points.add(coord);
          }
        }
      }

      if (points.length >= 2) {
        polylines.add(
          Polyline(
            points: points,
            color: _getCorridorColor(mission),
            strokeWidth: 5,
            strokeJoin: StrokeJoin.round,
            strokeCap: StrokeCap.round,
          ),
        );
      }
    }

    return PolylineLayer(polylines: polylines);
  }

  static Color _getCorridorColor(ActiveMission mission) {
    switch (mission.vehicle.type.name) {
      case 'ambulance':
        return AppColors.primary;
      case 'fire':
        return Colors.orange;
      case 'police':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }
}
