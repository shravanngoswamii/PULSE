import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/pulse_app_bar.dart';
import '../../../shared/widgets/pulse_bottom_nav.dart';
import '../../../shared/widgets/section_label.dart';
import '../simulation_controller.dart';
import '../widgets/simulation_map_view.dart';
import '../widgets/traffic_density_panel.dart';
import '../widgets/incident_type_panel.dart';
import '../widgets/emergency_type_selector.dart';
import '../widgets/simulation_action_bar.dart';
import '../widgets/simulation_event_log.dart';

class SimulationScreen extends ConsumerWidget {
  const SimulationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(simulationControllerProvider);
    final controller = ref.read(simulationControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PulseAppBar(
        title: 'SIMULATION CONTROL',
        subtitle: 'Traffic Scenario Simulator',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // Map View
            SimulationMapView(
              ambulancePosition: state.ambulancePosition,
              corridorWaypoints: state.corridorWaypoints,
              activeIncidentLocation: state.activeIncidentLocation,
              status: state.status,
            ),
            const SizedBox(height: 16),

            // Traffic Density Panel
            TrafficDensityPanel(
              config: state.config,
              onDensityChanged: controller.updateTrafficDensity,
              onVehiclesPerMinuteChanged: controller.updateVehiclesPerMinute,
              onSignalDelayChanged: controller.updateSignalDelay,
            ),
            const SizedBox(height: 16),

            // Incident Type Panel
            IncidentTypePanel(
              config: state.config,
              onIncidentTypeChanged: controller.updateIncidentType,
              onLocationChanged: controller.updateIncidentLocation,
              onSeverityChanged: controller.updateIncidentSeverity,
            ),
            const SizedBox(height: 16),

            // Emergency Type Selector
            EmergencyTypeSelector(
              selectedType: state.config.emergencyVehicleType,
              onTypeSelected: controller.updateEmergencyVehicleType,
              onSetStart: () => controller.setStartPosition(state.corridorWaypoints[0]),
              onSetDestination: () => controller.setDestination(state.corridorWaypoints.last),
            ),
            const SizedBox(height: 20),

            // Simulation Actions
            const SectionLabel(label: 'SIMULATION ACTIONS'),
            const SizedBox(height: 12),
            SimulationActionBar(
              status: state.status,
              onStart: controller.startSimulation,
              onPause: controller.pauseSimulation,
              onReset: controller.resetSimulation,
            ),
            const SizedBox(height: 20),

            // Event Log
            SimulationEventLog(
              events: state.eventLog,
              status: state.status,
            ),
            
            const SizedBox(height: 24),
            SizedBox(height: 16 + 64 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
      bottomNavigationBar: const PulseBottomNav(currentIndex: 0), // Dashboard active by instructions
    );
  }
}
