import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/intersection.dart';

class SignalMarker {
  static Marker create(Intersection intersection, {required VoidCallback onTap}) {
    return Marker(
      point: LatLng(intersection.lat, intersection.lng),
      width: 32,
      height: 32,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _getMarkerColor(intersection.currentPhase, intersection.signalMode),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
          child: const Icon(Icons.traffic, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  static Color _getMarkerColor(SignalPhase phase, SignalMode mode) {
    if (mode == SignalMode.emergency) return Colors.green;

    switch (phase) {
      case SignalPhase.green:
        return Colors.green;
      case SignalPhase.red:
        return Colors.red;
      case SignalPhase.amber:
        return Colors.amber;
      default:
        return Colors.red;
    }
  }
}
