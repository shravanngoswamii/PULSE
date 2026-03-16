import 'package:equatable/equatable.dart';
import 'emergency_vehicle.dart';
import 'traffic_alert.dart';

enum IncidentType { accident, congestion, signalFailure }

class SimulationConfig extends Equatable {
  final double trafficDensityPercent;
  final int vehiclesPerMinute;
  final int signalDelaySeconds;
  final IncidentType? incidentType;
  final String? incidentLocation;
  final Severity? incidentSeverity;
  final VehicleType emergencyVehicleType;
  final double? startLat;
  final double? startLng;
  final double? destinationLat;
  final double? destinationLng;
  final bool isRunning;
  final bool isPaused;

  const SimulationConfig({
    this.trafficDensityPercent = 0.5,
    this.vehiclesPerMinute = 30,
    this.signalDelaySeconds = 15,
    this.incidentType,
    this.incidentLocation,
    this.incidentSeverity,
    required this.emergencyVehicleType,
    this.startLat,
    this.startLng,
    this.destinationLat,
    this.destinationLng,
    this.isRunning = false,
    this.isPaused = false,
  });

  SimulationConfig copyWith({
    double? trafficDensityPercent,
    int? vehiclesPerMinute,
    int? signalDelaySeconds,
    IncidentType? incidentType,
    String? incidentLocation,
    Severity? incidentSeverity,
    VehicleType? emergencyVehicleType,
    double? startLat,
    double? startLng,
    double? destinationLat,
    double? destinationLng,
    bool? isRunning,
    bool? isPaused,
  }) {
    return SimulationConfig(
      trafficDensityPercent: trafficDensityPercent ?? this.trafficDensityPercent,
      vehiclesPerMinute: vehiclesPerMinute ?? this.vehiclesPerMinute,
      signalDelaySeconds: signalDelaySeconds ?? this.signalDelaySeconds,
      incidentType: incidentType ?? this.incidentType,
      incidentLocation: incidentLocation ?? this.incidentLocation,
      incidentSeverity: incidentSeverity ?? this.incidentSeverity,
      emergencyVehicleType: emergencyVehicleType ?? this.emergencyVehicleType,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  @override
  List<Object?> get props => [
        trafficDensityPercent,
        vehiclesPerMinute,
        signalDelaySeconds,
        incidentType,
        incidentLocation,
        incidentSeverity,
        emergencyVehicleType,
        startLat,
        startLng,
        destinationLat,
        destinationLng,
        isRunning,
        isPaused,
      ];
}
