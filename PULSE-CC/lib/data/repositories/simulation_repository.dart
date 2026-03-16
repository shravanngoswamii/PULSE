import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_config.dart';

enum SimEventType { dispatch, prediction, cleared, alert, recovery }

class SimulationEvent {
  final DateTime timestamp;
  final String message;
  final SimEventType type;

  SimulationEvent({
    required this.timestamp,
    required this.message,
    required this.type,
  });
}

abstract class SimulationRepository {
  Future<void> startSimulation(SimulationConfig config);
  Future<void> pauseSimulation();
  Future<void> resetSimulation();
  Stream<SimulationEvent> watchSimulationEvents();
}

class MockSimulationRepository implements SimulationRepository {
  @override
  Future<void> startSimulation(SimulationConfig config) async {
    // Stub
  }

  @override
  Future<void> pauseSimulation() async {
    // Stub
  }

  @override
  Future<void> resetSimulation() async {
    // Stub
  }

  @override
  Stream<SimulationEvent> watchSimulationEvents() async* {
    // Stub
  }
}

final simulationRepositoryProvider = Provider<SimulationRepository>((ref) {
  return MockSimulationRepository();
});
