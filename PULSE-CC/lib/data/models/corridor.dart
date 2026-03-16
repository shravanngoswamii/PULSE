import 'package:equatable/equatable.dart';
import 'intersection.dart';

class CorridorWaypoint extends Equatable {
  final double lat;
  final double lng;
  final String? intersectionId;
  final SignalPhase signalPhase;

  const CorridorWaypoint({
    required this.lat,
    required this.lng,
    this.intersectionId,
    required this.signalPhase,
  });

  @override
  List<Object?> get props => [lat, lng, intersectionId, signalPhase];
}

class Corridor extends Equatable {
  final String id;
  final String missionId;
  final List<CorridorWaypoint> waypoints;
  final bool isActive;
  final DateTime? activatedAt;

  const Corridor({
    required this.id,
    required this.missionId,
    required this.waypoints,
    required this.isActive,
    this.activatedAt,
  });

  @override
  List<Object?> get props => [id, missionId, waypoints, isActive, activatedAt];
}
