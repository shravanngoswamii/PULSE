import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/intersection.dart';

class SignalMarker {
  static Marker create(Intersection intersection, {required VoidCallback onTap}) {
    return Marker(
      markerId: MarkerId('signal_${intersection.id}'),
      position: LatLng(intersection.lat, intersection.lng),
      onTap: onTap,
      icon: BitmapDescriptor.defaultMarkerWithHue(
        _getMarkerHue(intersection.currentPhase, intersection.signalMode),
      ),
    );
  }

  static double _getMarkerHue(SignalPhase phase, SignalMode mode) {
    if (mode == SignalMode.emergency) return BitmapDescriptor.hueGreen;

    switch (phase) {
      case SignalPhase.green:
        return BitmapDescriptor.hueGreen;
      case SignalPhase.red:
        return BitmapDescriptor.hueRed;
      case SignalPhase.amber:
        return BitmapDescriptor.hueYellow;
      default:
        return BitmapDescriptor.hueRed;
    }
  }
}
