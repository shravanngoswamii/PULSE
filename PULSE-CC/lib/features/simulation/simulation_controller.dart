import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/traffic_alert.dart';
import '../../data/models/emergency_vehicle.dart';

enum SimulationStatus { idle, running, paused }

enum SimEventType { dispatch, prediction, cleared, alert, recovery, density }

class SimulationEvent {
  final DateTime timestamp;
  final String message;
  final SimEventType type;

  const SimulationEvent({
    required this.timestamp,
    required this.message,
    required this.type,
  });
}

class SimulationConfig {
  final double trafficDensityPercent;
  final int vehiclesPerMinute;
  final int signalDelaySeconds;
  final AlertType? incidentType;
  final String? incidentLocation;
  final Severity incidentSeverity;
  final VehicleType emergencyVehicleType;

  const SimulationConfig({
    this.trafficDensityPercent = 0.65,
    this.vehiclesPerMinute = 150,
    this.signalDelaySeconds = 12,
    this.incidentType = AlertType.accident,
    this.incidentLocation = "MG Road Sector 4",
    this.incidentSeverity = Severity.medium,
    this.emergencyVehicleType = VehicleType.ambulance,
  });

  SimulationConfig copyWith({
    double? trafficDensityPercent,
    int? vehiclesPerMinute,
    int? signalDelaySeconds,
    AlertType? incidentType,
    String? incidentLocation,
    Severity? incidentSeverity,
    VehicleType? emergencyVehicleType,
  }) {
    return SimulationConfig(
      trafficDensityPercent: trafficDensityPercent ?? this.trafficDensityPercent,
      vehiclesPerMinute: vehiclesPerMinute ?? this.vehiclesPerMinute,
      signalDelaySeconds: signalDelaySeconds ?? this.signalDelaySeconds,
      incidentType: incidentType ?? this.incidentType,
      incidentLocation: incidentLocation ?? this.incidentLocation,
      incidentSeverity: incidentSeverity ?? this.incidentSeverity,
      emergencyVehicleType: emergencyVehicleType ?? this.emergencyVehicleType,
    );
  }
}

class SimulationState {
  final SimulationConfig config;
  final SimulationStatus status;
  final List<SimulationEvent> eventLog;
  final int elapsedSeconds;
  final LatLng? ambulancePosition;
  final List<LatLng> corridorWaypoints;
  final String? activeIncidentLocation;

  SimulationState({
    required this.config,
    required this.status,
    required this.eventLog,
    required this.elapsedSeconds,
    this.ambulancePosition,
    required this.corridorWaypoints,
    this.activeIncidentLocation,
  });

  SimulationState copyWith({
    SimulationConfig? config,
    SimulationStatus? status,
    List<SimulationEvent>? eventLog,
    int? elapsedSeconds,
    LatLng? ambulancePosition,
    List<LatLng>? corridorWaypoints,
    String? activeIncidentLocation,
  }) {
    return SimulationState(
      config: config ?? this.config,
      status: status ?? this.status,
      eventLog: eventLog ?? this.eventLog,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      ambulancePosition: ambulancePosition ?? this.ambulancePosition,
      corridorWaypoints: corridorWaypoints ?? this.corridorWaypoints,
      activeIncidentLocation: activeIncidentLocation ?? this.activeIncidentLocation,
    );
  }
}

class SimulationController extends StateNotifier<SimulationState> {
  Timer? _timer;

  static final List<LatLng> _waypoints = [
    const LatLng(22.7134, 75.8621), // Sarwate
    const LatLng(22.7185, 75.8571), // Rajwada
    const LatLng(22.7196, 75.8577), // Geeta Bhawan
    const LatLng(22.7299, 75.8656), // Bhanwar Kuwa
    const LatLng(22.7271, 75.8835), // MG Road
    const LatLng(22.7236, 75.8798), // Palasia
    const LatLng(22.7515, 75.8770), // Bombay Hospital
  ];

  SimulationController()
      : super(SimulationState(
          config: const SimulationConfig(),
          status: SimulationStatus.idle,
          eventLog: [],
          elapsedSeconds: 0,
          ambulancePosition: _waypoints[0],
          corridorWaypoints: _waypoints,
          activeIncidentLocation: "MG Road Sector 4",
        ));

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void updateTrafficDensity(double value) =>
      state = state.copyWith(config: state.config.copyWith(trafficDensityPercent: value));

  void updateVehiclesPerMinute(int value) =>
      state = state.copyWith(config: state.config.copyWith(vehiclesPerMinute: value));

  void updateSignalDelay(int seconds) =>
      state = state.copyWith(config: state.config.copyWith(signalDelaySeconds: seconds));

  void updateIncidentType(AlertType? type) =>
      state = state.copyWith(config: state.config.copyWith(incidentType: type));

  void updateIncidentLocation(String location) =>
      state = state.copyWith(config: state.config.copyWith(incidentLocation: location));

  void updateIncidentSeverity(Severity severity) =>
      state = state.copyWith(config: state.config.copyWith(incidentSeverity: severity));

  void updateEmergencyVehicleType(VehicleType type) =>
      state = state.copyWith(config: state.config.copyWith(emergencyVehicleType: type));

  void setStartPosition(LatLng position) {
    // Logic to set start point (visual only in mock)
  }

  void setDestination(LatLng position) {
    // Logic to set destination (visual only in mock)
  }

  void _addEvent(String message, SimEventType type) {
    state = state.copyWith(
      eventLog: [
        SimulationEvent(timestamp: DateTime.now(), message: message, type: type),
        ...state.eventLog,
      ],
    );
  }

  void startSimulation() {
    if (state.status == SimulationStatus.running) return;
    state = state.copyWith(status: SimulationStatus.running);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final t = state.elapsedSeconds + 1;
      state = state.copyWith(elapsedSeconds: t);
      _processTick(t);
    });
  }

  void pauseSimulation() {
    _timer?.cancel();
    state = state.copyWith(status: SimulationStatus.paused);
  }

  void resetSimulation() {
    _timer?.cancel();
    state = state.copyWith(
      status: SimulationStatus.idle,
      elapsedSeconds: 0,
      eventLog: [],
      ambulancePosition: _waypoints[0],
    );
  }

  void _processTick(int t) {
    switch (t) {
      case 1:
        _addEvent("Ambulance AMB-04 dispatched", SimEventType.dispatch);
        state = state.copyWith(ambulancePosition: _waypoints[0]);
        break;
      case 3:
        _addEvent("LSTM: ETA predictions calculated\nMG Road: 22s · C.Square: 48s · Market: 73s", SimEventType.prediction);
        break;
      case 5:
        _addEvent("MG Road junction pre-cleared\nSignal priority activated — 17s ahead", SimEventType.cleared);
        break;
      case 8:
        state = state.copyWith(ambulancePosition: _waypoints[1]);
        break;
      case 12:
        _addEvent("Traffic density reduced on route corridor", SimEventType.density);
        break;
      case 22:
        _addEvent("MG Road Junction cleared", SimEventType.cleared);
        state = state.copyWith(ambulancePosition: _waypoints[2]);
        break;
      case 25:
        _addEvent("C. Square pre-cleared — 23s ahead", SimEventType.cleared);
        break;
      case 35:
        _addEvent("Minor congestion detected — Tunnel B", SimEventType.alert);
        break;
      case 48:
        _addEvent("C. Square Junction cleared", SimEventType.cleared);
        state = state.copyWith(ambulancePosition: _waypoints[3]);
        break;
      case 60:
        _addEvent("Market St Junction cleared", SimEventType.cleared);
        state = state.copyWith(ambulancePosition: _waypoints[4]);
        break;
      case 73:
        _addEvent("Ambulance arrived at City Hospital\nTraffic recovery initiated", SimEventType.recovery);
        break;
      case 80:
        _addEvent("All intersections restored to automatic", SimEventType.recovery);
        resetSimulation();
        break;
    }
  }
}

final simulationControllerProvider =
    StateNotifierProvider<SimulationController, SimulationState>((ref) {
  final controller = SimulationController();
  ref.onDispose(() => controller.dispose());
  return controller;
});
