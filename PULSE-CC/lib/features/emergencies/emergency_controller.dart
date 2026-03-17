import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/active_mission.dart';
import '../../data/models/traffic_alert.dart';
import '../../data/models/emergency_vehicle.dart';
import '../../data/repositories/mission_repository.dart';
import '../../data/repositories/alert_repository.dart';
import '../../data/sources/remote/pulse_websocket.dart';

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
  final PulseWebSocket _webSocket;
  StreamSubscription? _wsSub;

  EmergencyController({
    required MissionRepository missionRepo,
    required AlertRepository alertRepo,
    required PulseWebSocket webSocket,
  })  : _missionRepo = missionRepo,
        _alertRepo = alertRepo,
        _webSocket = webSocket,
        super(EmergencyState()) {
    initialize();
    _startWebSocket();
  }

  void _startWebSocket() async {
    await _webSocket.connect();
    _wsSub = _webSocket.eventStream.listen((data) {
      final event = data['event'] as String? ?? '';
      switch (event) {
        case 'mission_started':
        case 'mission_completed':
          refreshMissions();
          break;
        case 'vehicle_position':
          _handleVehiclePosition(data);
          break;
      }
    });
  }

  void _handleVehiclePosition(Map<String, dynamic> data) {
    final vehicleId = data['vehicle_id'] as String?;
    if (vehicleId == null) return;
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    final updated = state.activeMissions.map((m) {
      if (m.vehicle.id == vehicleId) {
        final etaMin = (data['eta_minutes'] as num?)?.toDouble();
        return m.copyWith(
          vehicle: m.vehicle.copyWith(
            currentLat: lat,
            currentLng: lng,
            etaSeconds: etaMin != null ? (etaMin * 60).toInt() : null,
          ),
        );
      }
      return m;
    }).toList();

    final primary = state.primaryMission;
    if (primary != null && primary.vehicle.id == vehicleId) {
      final etaMin = (data['eta_minutes'] as num?)?.toDouble();
      state = state.copyWith(
        activeMissions: updated,
        primaryMission: primary.copyWith(
          vehicle: primary.vehicle.copyWith(
            currentLat: lat,
            currentLng: lng,
            etaSeconds: etaMin != null ? (etaMin * 60).toInt() : null,
          ),
        ),
      );
    } else {
      state = state.copyWith(activeMissions: updated);
    }
  }

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      final missions = await _missionRepo.getActiveMissions();
      final alerts = await _alertRepo.getAlerts();

      final ambulanceMissions = missions
          .where((m) => m.vehicle.type == VehicleType.ambulance)
          .toList();
      final primary = ambulanceMissions.isNotEmpty
          ? ambulanceMissions.first
          : (missions.isNotEmpty ? missions.first : null);

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

  Future<void> clearAlert(String alertId) async {
    try {
      await _alertRepo.clearAlert(alertId);
      final updatedAlerts =
          state.alerts.where((a) => a.id != alertId).toList();
      state = state.copyWith(alerts: updatedAlerts);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to clear alert');
    }
  }

  Future<void> refreshMissions() async {
    try {
      final missions = await _missionRepo.getActiveMissions();
      final alerts = await _alertRepo.getAlerts();

      final ambulanceMissions = missions
          .where((m) => m.vehicle.type == VehicleType.ambulance)
          .toList();
      final primary = ambulanceMissions.isNotEmpty
          ? ambulanceMissions.first
          : (missions.isNotEmpty ? missions.first : null);

      state = state.copyWith(
        activeMissions: missions,
        primaryMission: primary,
        alerts: alerts,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }
}

final emergencyControllerProvider =
    StateNotifierProvider<EmergencyController, EmergencyState>((ref) {
  final missionRepo = ref.watch(missionRepositoryProvider);
  final alertRepo = ref.watch(alertRepositoryProvider);
  final webSocket = ref.watch(websocketProvider);
  return EmergencyController(missionRepo: missionRepo, alertRepo: alertRepo, webSocket: webSocket);
});
