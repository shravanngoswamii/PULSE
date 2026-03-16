import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_ev/features/simulation/models/simulation_model.dart';
import 'package:pulse_ev/features/settings/providers/settings_provider.dart';

class SimulationNotifier extends StateNotifier<SimulationModel> {
  SimulationNotifier() : super(SimulationModel.initial());

  void updateFromSettings(bool enabled) {
    state = state.copyWith(simulationEnabled: enabled);
  }

  void startSimulation() {
    state = state.copyWith(simulationActive: true);
  }

  void resetSimulation() {
    state = SimulationModel.initial().copyWith(simulationEnabled: state.simulationEnabled);
  }

  void updateTrafficDensity(String density) {
    state = state.copyWith(trafficDensity: density);
  }

  void updateIncident(IncidentType type) {
    state = state.copyWith(incidentType: type);
  }

  void updateSeverity(Severity severity) {
    state = state.copyWith(severity: severity);
  }

  void updateEmergencyVehicle(EmergencyVehicleType type) {
    state = state.copyWith(emergencyVehicleType: type);
  }

  void updateSignalDelay(int delay) {
    state = state.copyWith(signalDelay: delay);
  }

  void updateVehiclesPerMinute(int vpm) {
    state = state.copyWith(vehiclesPerMinute: vpm);
  }
}

final simulationProvider = StateNotifierProvider<SimulationNotifier, SimulationModel>((ref) {
  final notifier = SimulationNotifier();
  // Sync with settings
  final settings = ref.watch(settingsProvider);
  notifier.updateFromSettings(settings.simulationMode);
  return notifier;
});
