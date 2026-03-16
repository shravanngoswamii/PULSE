enum IncidentType {
  vehicleCollision,
  fire,
  roadblock,
}

enum Severity {
  low,
  medium,
  high,
}

enum EmergencyVehicleType {
  ambulance,
  fire,
  police,
}

class SimulationModel {
  final String trafficDensity;
  final int signalDelay;
  final int vehiclesPerMinute;
  final IncidentType incidentType;
  final String incidentLocation;
  final Severity severity;
  final EmergencyVehicleType emergencyVehicleType;
  final bool simulationActive;
  final bool simulationEnabled;

  SimulationModel({
    required this.trafficDensity,
    required this.signalDelay,
    required this.vehiclesPerMinute,
    required this.incidentType,
    required this.incidentLocation,
    required this.severity,
    required this.emergencyVehicleType,
    required this.simulationActive,
    required this.simulationEnabled,
  });

  SimulationModel copyWith({
    String? trafficDensity,
    int? signalDelay,
    int? vehiclesPerMinute,
    IncidentType? incidentType,
    String? incidentLocation,
    Severity? severity,
    EmergencyVehicleType? emergencyVehicleType,
    bool? simulationActive,
    bool? simulationEnabled,
  }) {
    return SimulationModel(
      trafficDensity: trafficDensity ?? this.trafficDensity,
      signalDelay: signalDelay ?? this.signalDelay,
      vehiclesPerMinute: vehiclesPerMinute ?? this.vehiclesPerMinute,
      incidentType: incidentType ?? this.incidentType,
      incidentLocation: incidentLocation ?? this.incidentLocation,
      severity: severity ?? this.severity,
      emergencyVehicleType: emergencyVehicleType ?? this.emergencyVehicleType,
      simulationActive: simulationActive ?? this.simulationActive,
      simulationEnabled: simulationEnabled ?? this.simulationEnabled,
    );
  }

  factory SimulationModel.initial() {
    return SimulationModel(
      trafficDensity: "Moderate",
      signalDelay: 30,
      vehiclesPerMinute: 60,
      incidentType: IncidentType.vehicleCollision,
      incidentLocation: "Market St & 5th Ave",
      severity: Severity.medium,
      emergencyVehicleType: EmergencyVehicleType.ambulance,
      simulationActive: false,
      simulationEnabled: false,
    );
  }
}
