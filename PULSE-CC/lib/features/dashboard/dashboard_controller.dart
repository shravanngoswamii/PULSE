import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/active_mission.dart';
import '../../data/models/intersection.dart';
import '../../data/repositories/mission_repository.dart';
import '../../data/repositories/intersection_repository.dart';
import '../../data/sources/remote/pulse_api_client.dart';
import '../../data/sources/remote/pulse_websocket.dart';
import '../../core/constants/api_constants.dart';

class SystemStatus {
  final int activeSignals;
  final int activeEmergencies;
  final int congestedRoads;
  final int averageDelaySeconds;
  final int activeAlerts;

  const SystemStatus({
    this.activeSignals = 0,
    this.activeEmergencies = 0,
    this.congestedRoads = 0,
    this.averageDelaySeconds = 0,
    this.activeAlerts = 0,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    return SystemStatus(
      activeSignals: json['activeSignals'] as int? ?? json['active_signals'] as int? ?? 0,
      activeEmergencies: json['activeEmergencies'] as int? ?? json['active_emergencies'] as int? ?? 0,
      congestedRoads: json['congestedRoads'] as int? ?? json['congested_roads'] as int? ?? 0,
      averageDelaySeconds: json['averageDelaySeconds'] as int? ?? json['average_delay_seconds'] as int? ?? json['avg_delay'] as int? ?? 0,
      activeAlerts: json['activeAlerts'] as int? ?? json['active_alerts'] as int? ?? 0,
    );
  }
}

/// A notification about a driver approaching an intersection.
class ApproachingVehicleAlert {
  final String missionId;
  final String vehicleId;
  final String vehicleType;
  final String intersectionName;
  final String message;
  final String priority;
  final DateTime timestamp;

  ApproachingVehicleAlert({
    required this.missionId,
    required this.vehicleId,
    required this.vehicleType,
    required this.intersectionName,
    required this.message,
    required this.priority,
    required this.timestamp,
  });
}

class DashboardState {
  final List<ActiveMission> activeMissions;
  final List<Intersection> intersections;
  final bool isLoading;
  final String? errorMessage;
  final SystemStatus systemStatus;
  final List<ApproachingVehicleAlert> approachingAlerts;

  const DashboardState({
    this.activeMissions = const [],
    this.intersections = const [],
    this.isLoading = false,
    this.errorMessage,
    this.systemStatus = const SystemStatus(),
    this.approachingAlerts = const [],
  });

  DashboardState copyWith({
    List<ActiveMission>? activeMissions,
    List<Intersection>? intersections,
    bool? isLoading,
    String? errorMessage,
    SystemStatus? systemStatus,
    List<ApproachingVehicleAlert>? approachingAlerts,
  }) {
    return DashboardState(
      activeMissions: activeMissions ?? this.activeMissions,
      intersections: intersections ?? this.intersections,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      systemStatus: systemStatus ?? this.systemStatus,
      approachingAlerts: approachingAlerts ?? this.approachingAlerts,
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  final MissionRepository _missionRepo;
  final IntersectionRepository _intersectionRepo;
  final PulseApiClient _apiClient;
  final PulseWebSocket _webSocket;
  StreamSubscription? _wsSub;
  Timer? _refreshTimer;

  DashboardController(
    this._missionRepo,
    this._intersectionRepo,
    this._apiClient,
    this._webSocket,
  ) : super(const DashboardState());

  Future<void> initialize() async {
    if (state.activeMissions.isNotEmpty) return;
    await refresh();
    _startWebSocket();
    // Auto-refresh every 15 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
  }

  void _startWebSocket() async {
    await _webSocket.connect();
    _wsSub = _webSocket.eventStream.listen((data) {
      final event = data['event'] as String? ?? data['type'] as String? ?? '';
      switch (event) {
        case 'mission_started':
        case 'mission_completed':
          refresh();
          break;
        case 'vehicle_position':
          _handleVehiclePosition(data);
          break;
        case 'intersection_alert':
          _handleApproachingVehicle(data);
          break;
        case 'signal_change':
          refresh();
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

    final updatedMissions = state.activeMissions.map((m) {
      if (m.vehicle.id == vehicleId) {
        return m.copyWith(
          vehicle: m.vehicle.copyWith(currentLat: lat, currentLng: lng),
        );
      }
      return m;
    }).toList();
    state = state.copyWith(activeMissions: updatedMissions);
  }

  void _handleApproachingVehicle(Map<String, dynamic> data) {
    final alert = ApproachingVehicleAlert(
      missionId: data['mission_id'] as String? ?? '',
      vehicleId: data['vehicle_id'] as String? ?? '',
      vehicleType: data['vehicle_type'] as String? ?? 'ambulance',
      intersectionName: data['intersection_name'] as String? ?? '',
      message: data['message'] as String? ?? 'Emergency vehicle approaching',
      priority: data['priority'] as String? ?? 'high',
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      approachingAlerts: [...state.approachingAlerts, alert],
    );

    // Auto-dismiss after 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        state = state.copyWith(
          approachingAlerts: state.approachingAlerts
              .where((a) => a.missionId != alert.missionId || a.intersectionName != alert.intersectionName)
              .toList(),
        );
      }
    });
  }

  void dismissAlert(ApproachingVehicleAlert alert) {
    state = state.copyWith(
      approachingAlerts: state.approachingAlerts
          .where((a) => a != alert)
          .toList(),
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final futures = await Future.wait([
        _missionRepo.getActiveMissions(),
        _intersectionRepo.getIntersections(),
        _fetchSystemStatus(),
      ]);
      final missions = futures[0] as List<ActiveMission>;
      final intersections = futures[1] as List<Intersection>;
      final status = futures[2] as SystemStatus;

      state = state.copyWith(
        activeMissions: missions,
        intersections: intersections,
        systemStatus: status,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load dashboard data',
      );
    }
  }

  Future<SystemStatus> _fetchSystemStatus() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.operatorState);
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final statsJson = data['stats'] as Map<String, dynamic>? ?? data;
        return SystemStatus.fromJson(statsJson);
      }
    } catch (_) {}
    return const SystemStatus();
  }

  Future<void> forceSignal(String intersectionId, SignalPhase phase) async {
    try {
      await _intersectionRepo.forceSignal(intersectionId, phase);
      await refresh();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to override signal');
    }
  }

  Future<void> restoreAutoControl(String intersectionId) async {
    try {
      await _intersectionRepo.restoreAutomatic(intersectionId);
      await refresh();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to restore auto control');
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  final missionRepo = ref.watch(missionRepositoryProvider);
  final intersectionRepo = ref.watch(intersectionRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  final webSocket = ref.watch(websocketProvider);
  return DashboardController(missionRepo, intersectionRepo, apiClient, webSocket);
});
