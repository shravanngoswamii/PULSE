import 'package:equatable/equatable.dart';
import 'emergency_vehicle.dart';

enum MissionStatus { active, completed, cancelled }
enum ClearanceStatus { green, pending, cleared }
enum EventType { info, warning, cleared, rerouted }

class MissionEvent extends Equatable {
  final DateTime timestamp;
  final String message;
  final EventType type;
  final String? subtitle;

  const MissionEvent({
    required this.timestamp,
    required this.message,
    required this.type,
    this.subtitle,
  });

  @override
  List<Object?> get props => [timestamp, message, type, subtitle];
}

class ActiveMission extends Equatable {
  final String id;
  final EmergencyVehicle vehicle;
  final List<String> routeIntersections;
  final Map<String, ClearanceStatus> junctionClearance;
  final DateTime startTime;
  final DateTime estimatedArrival;
  final MissionStatus status;
  final List<MissionEvent> eventLog;
  /// Road coordinates for rendering the route polyline on maps.
  /// Each entry is [lat, lng].
  final List<List<double>> roadCoordinates;

  const ActiveMission({
    required this.id,
    required this.vehicle,
    required this.routeIntersections,
    required this.junctionClearance,
    required this.startTime,
    required this.estimatedArrival,
    required this.status,
    required this.eventLog,
    this.roadCoordinates = const [],
  });

  ActiveMission copyWith({
    String? id,
    EmergencyVehicle? vehicle,
    List<String>? routeIntersections,
    Map<String, ClearanceStatus>? junctionClearance,
    DateTime? startTime,
    DateTime? estimatedArrival,
    MissionStatus? status,
    List<MissionEvent>? eventLog,
    List<List<double>>? roadCoordinates,
  }) {
    return ActiveMission(
      id: id ?? this.id,
      vehicle: vehicle ?? this.vehicle,
      routeIntersections: routeIntersections ?? this.routeIntersections,
      junctionClearance: junctionClearance ?? this.junctionClearance,
      startTime: startTime ?? this.startTime,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      status: status ?? this.status,
      eventLog: eventLog ?? this.eventLog,
      roadCoordinates: roadCoordinates ?? this.roadCoordinates,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vehicle,
        routeIntersections,
        junctionClearance,
        startTime,
        estimatedArrival,
        status,
        eventLog,
        roadCoordinates,
      ];
}
