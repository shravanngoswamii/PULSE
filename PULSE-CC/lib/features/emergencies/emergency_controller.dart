import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/active_mission.dart';
import '../../data/models/traffic_alert.dart';
import '../../data/models/emergency_vehicle.dart';
import '../../data/repositories/mission_repository.dart';
import '../../data/repositories/alert_repository.dart';
// import '../../data/repositories/mock_mission_repository.dart';
// import '../../data/repositories/mock_alert_repository.dart';

class EmergencyState {
  final List<ActiveMission> activeMissions;
  final ActiveMission? primaryMission;
  final List<TrafficAlert> alerts;
  final AlertType? activeFilter;
  final bool isLoading;
  final String? errorMessage;

  EmergencyState({
    this.activeMissions = const [],
    this.primaryMission,
    this.alerts = const [],
    this.activeFilter,
    this.isLoading = false,
    this.errorMessage,
  });

  List<TrafficAlert> get filteredAlerts {
    if (activeFilter == null) return alerts;
    return alerts.where((a) => a.type == activeFilter).toList();
  }

  EmergencyState copyWith({
    List<ActiveMission>? activeMissions,
    ActiveMission? primaryMission,
    List<TrafficAlert>? alerts,
    AlertType? activeFilter,
    bool? isLoading,
    String? errorMessage,
  }) {
    return EmergencyState(
      activeMissions: activeMissions ?? this.activeMissions,
      primaryMission: primaryMission ?? this.primaryMission,
      alerts: alerts ?? this.alerts,
      activeFilter: activeFilter ?? this.activeFilter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class EmergencyController extends StateNotifier<EmergencyState> {
  final MissionRepository _missionRepo;
  final AlertRepository _alertRepo;

  EmergencyController({
    required MissionRepository missionRepo,
    required AlertRepository alertRepo,
  })  : _missionRepo = missionRepo,
        _alertRepo = alertRepo,
        super(EmergencyState()) {
    initialize();
  }

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      final missions = await _missionRepo.getActiveMissions();
      final alerts = await _alertRepo.getAlerts();
      
      final ambulanceMissions = missions.where((m) => m.vehicle.type == VehicleType.ambulance).toList();
      final primary = ambulanceMissions.isNotEmpty ? ambulanceMissions.first : (missions.isNotEmpty ? missions.first : null);

      state = state.copyWith(
        activeMissions: missions,
        primaryMission: primary,
        alerts: alerts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load emergency data',
        isLoading: false,
      );
    }
  }

  void setFilter(AlertType? type) {
    state = state.copyWith(activeFilter: type);
  }

  void clearAlert(String alertId) {
    final updatedAlerts = state.alerts.where((a) => a.id != alertId).toList();
    state = state.copyWith(alerts: updatedAlerts);
  }

  Future<void> refreshMissions() async {
    final missions = await _missionRepo.getActiveMissions();
    state = state.copyWith(activeMissions: missions);
  }
}

final emergencyControllerProvider = StateNotifierProvider<EmergencyController, EmergencyState>((ref) {
  final missionRepo = ref.watch(missionRepositoryProvider);
  final alertRepo = ref.watch(alertRepositoryProvider);
  return EmergencyController(missionRepo: missionRepo, alertRepo: alertRepo);
});
