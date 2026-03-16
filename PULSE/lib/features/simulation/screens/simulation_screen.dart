import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/features/simulation/models/simulation_model.dart';
import 'package:pulse_ev/features/simulation/providers/simulation_provider.dart';
import 'package:pulse_ev/shared/widgets/app_button.dart';
import 'package:pulse_ev/shared/widgets/section_card.dart';
import 'package:pulse_ev/shared/widgets/pulse_map.dart';

class SimulationScreen extends ConsumerWidget {
  const SimulationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simulation = ref.watch(simulationProvider);
    final notifier = ref.read(simulationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              'SIMULATION CONTROL',
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Traffic Scenario Simulator',
              style: AppTextStyles.micro,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Map View
            Container(
              height: 250,
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: const PulseMap(),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // 2. Traffic Simulation Section
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.traffic, color: AppColors.secondary, size: 20),
                            const SizedBox(width: 8),
                            Text('TRAFFIC SIMULATION', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownRow(
                          'TRAFFIC DENSITY',
                          simulation.trafficDensity,
                          ['Low', 'Moderate', 'High'],
                          (v) => notifier.updateTrafficDensity(v!),
                          AppColors.secondary,
                        ),
                        const SizedBox(height: 16),
                        _buildSliderRow(
                          'SIGNAL DELAY',
                          '${simulation.signalDelay}s',
                          simulation.signalDelay.toDouble(),
                          10,
                          120,
                          (v) => notifier.updateSignalDelay(v.toInt()),
                          AppColors.secondary,
                        ),
                        const SizedBox(height: 16),
                        Text('VEHICLES PER MINUTE', style: AppTextStyles.micro),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: InputDecoration(
                            hintText: '120',
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => notifier.updateVehiclesPerMinute(int.tryParse(v) ?? 60),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Incident Simulation Section
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text('INCIDENT SIMULATION', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Incident Type', style: AppTextStyles.micro),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<IncidentType>(
                              value: simulation.incidentType,
                              isExpanded: true,
                              items: IncidentType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(_getIncidentName(type), style: AppTextStyles.label),
                                );
                              }).toList(),
                              onChanged: (v) => notifier.updateIncident(v!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.secondary, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(simulation.incidentLocation, style: AppTextStyles.label)),
                              const Text('CHANGE', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Severity', style: AppTextStyles.micro),
                        const SizedBox(height: 8),
                        Row(
                          children: Severity.values.map((s) {
                            final isSelected = simulation.severity == s;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: InkWell(
                                  onTap: () => notifier.updateSeverity(s),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.orange.withValues(alpha: 0.1) : Colors.white,
                                      border: Border.all(color: isSelected ? Colors.orange : AppColors.border),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        s.name.toUpperCase(),
                                        style: AppTextStyles.micro.copyWith(
                                          color: isSelected ? Colors.orange : AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Emergency Simulation Section
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.emergency, color: AppColors.emergency, size: 20),
                            const SizedBox(width: 8),
                            Text('EMERGENCY SIMULATION', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: EmergencyVehicleType.values.map((v) {
                            final isSelected = simulation.emergencyVehicleType == v;
                            return InkWell(
                              onTap: () => notifier.updateEmergencyVehicle(v),
                              child: Column(
                                children: [
                                  Icon(
                                    _getVehicleIcon(v),
                                    color: isSelected ? AppColors.emergency : AppColors.textSecondary,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    v.name.toUpperCase(),
                                    style: AppTextStyles.micro.copyWith(
                                      color: isSelected ? AppColors.emergency : AppColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      height: 2,
                                      width: 40,
                                      color: AppColors.emergency,
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionSmall(Icons.alt_route, 'OPTIMIZE ROUTE'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionSmall(Icons.bolt, 'PRIORITY GREEN'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 5. Simulation Buttons
                  AppButton(
                    text: 'START SIMULATION',
                    variant: ButtonVariant.primary,
                    onPressed: () => notifier.startSimulation(),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'RESET SCENARIO',
                    variant: ButtonVariant.secondary,
                    onPressed: () => notifier.resetSimulation(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownRow(String label, String value, List<String> items, Function(String?) onChanged, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.micro),
        DropdownButton<String>(
          value: value,
          underline: const SizedBox(),
          icon: Icon(Icons.arrow_drop_down, color: color),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: AppTextStyles.micro.copyWith(color: color, fontWeight: FontWeight.bold)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSliderRow(String label, String value, double current, double min, double max, Function(double) onChanged, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.micro),
            Text(value, style: AppTextStyles.micro.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            thumbColor: color,
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.2),
            overlayColor: color.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: current,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildActionSmall(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.textPrimary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  String _getIncidentName(IncidentType type) {
    switch (type) {
      case IncidentType.vehicleCollision:
        return 'Vehicle Collision';
      case IncidentType.fire:
        return 'Fire';
      case IncidentType.roadblock:
        return 'Roadblock';
    }
  }

  IconData _getVehicleIcon(EmergencyVehicleType type) {
    switch (type) {
      case EmergencyVehicleType.ambulance:
        return Icons.medical_services;
      case EmergencyVehicleType.fire:
        return Icons.fire_truck;
      case EmergencyVehicleType.police:
        return Icons.local_police;
    }
  }
}
