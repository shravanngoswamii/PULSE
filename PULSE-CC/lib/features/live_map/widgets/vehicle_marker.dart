import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/active_mission.dart';
import '../../../data/models/emergency_vehicle.dart';

class VehicleMarker {
  static Marker create(ActiveMission mission, {required int etaMinutes}) {
    return Marker(
      markerId: MarkerId('vehicle_${mission.vehicle.id}'),
      position: LatLng(mission.vehicle.currentLat, mission.vehicle.currentLng),
      infoWindow: InfoWindow(
        title: '${mission.vehicle.id} / ETA: ${etaMinutes}m',
        snippet: '${mission.vehicle.originName} → ${mission.vehicle.destinationName}',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        _getMarkerHue(mission.vehicle.type),
      ),
    );
  }

  static double _getMarkerHue(VehicleType type) {
    switch (type) {
      case VehicleType.ambulance:
        return BitmapDescriptor.hueGreen;
      case VehicleType.fire:
        return BitmapDescriptor.hueOrange;
      case VehicleType.police:
        return BitmapDescriptor.hueBlue;
    }
  }
}
