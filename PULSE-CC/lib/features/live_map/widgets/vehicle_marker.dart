import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/active_mission.dart';
import '../../../data/models/emergency_vehicle.dart';

class VehicleMarker {
  static Marker create(ActiveMission mission, {required int etaMinutes}) {
    return Marker(
      point: LatLng(mission.vehicle.currentLat, mission.vehicle.currentLng),
      width: 40,
      height: 40,
      child: Tooltip(
        message: '${mission.vehicle.id} / ETA: ${etaMinutes}m\n${mission.vehicle.originName} → ${mission.vehicle.destinationName}',
        child: Container(
          decoration: BoxDecoration(
            color: _getMarkerColor(mission.vehicle.type),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(
            _getMarkerIcon(mission.vehicle.type),
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  static Color _getMarkerColor(VehicleType type) {
    switch (type) {
      case VehicleType.ambulance:
        return Colors.green;
      case VehicleType.fire:
        return Colors.orange;
      case VehicleType.police:
        return Colors.blue;
    }
  }

  static IconData _getMarkerIcon(VehicleType type) {
    switch (type) {
      case VehicleType.ambulance:
        return Icons.local_hospital;
      case VehicleType.fire:
        return Icons.local_fire_department;
      case VehicleType.police:
        return Icons.local_police;
    }
  }
}
