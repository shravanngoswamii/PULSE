import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/active_mission.dart';

class CorridorOverlay {
  static Set<Polyline> getCorridors(List<ActiveMission> missions) {
    final Set<Polyline> polylines = {};

    for (var mission in missions) {
      if (mission.vehicle.id == 'A-12') {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('A-12-corridor'),
            color: AppColors.primary,
            width: 5,
            jointType: JointType.round,
            endCap: Cap.roundCap,
            startCap: Cap.roundCap,
            points: const [
              LatLng(18.5120, 73.8456), // Central Station
              LatLng(18.5160, 73.8490), // MG Road approach
              LatLng(18.5190, 73.8520), // MG Road junction
              LatLng(18.5210, 73.8545), // C. Square approach
              LatLng(18.5230, 73.8567), // C. Square junction
              LatLng(18.5260, 73.8590), // Market St approach
              LatLng(18.5290, 73.8610), // City Hospital
            ],
          ),
        );
      }
    }

    return polylines;
  }
}
