import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/active_mission.dart';

class CorridorOverlay {
  static PolylineLayer getCorridorLayer(List<ActiveMission> missions) {
    final List<Polyline> polylines = [];

    for (var mission in missions) {
      if (mission.vehicle.id == 'A-12') {
        polylines.add(
          Polyline(
            points: const [
              LatLng(22.7134, 75.8621), // Sarwate
              LatLng(22.7185, 75.8571), // Rajwada
              LatLng(22.7196, 75.8577), // Geeta Bhawan
              LatLng(22.7299, 75.8656), // Bhanwar Kuwa
              LatLng(22.7271, 75.8835), // MG Road
              LatLng(22.7236, 75.8798), // Palasia
              LatLng(22.7515, 75.8770), // Bombay Hospital
            ],
            color: AppColors.primary,
            strokeWidth: 5,
            strokeJoin: StrokeJoin.round,
            strokeCap: StrokeCap.round,
          ),
        );
      }
    }

    return PolylineLayer(polylines: polylines);
  }
}
