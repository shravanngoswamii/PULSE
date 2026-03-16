import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/active_mission.dart';
import '../../data/models/intersection.dart';
import '../../data/repositories/mission_repository.dart';
import '../../data/repositories/intersection_repository.dart';
import '../../data/sources/remote/pulse_api_client.dart';
import '../../core/constants/api_constants.dart';

class SystemStatus {
  final int activeSignals;
  final int activeEmergencies;
  final int congestedRoads;
  final int averageDelaySeconds;

  const SystemStatus({
    this.activeSignals = 0,
    this.activeEmergencies = 0,
    this.congestedRoads = 0,
    this.averageDelaySeconds = 0,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    // Try both camelCase and snake_case keys
    return SystemStatus(
      activeSignals: json['activeSignals'] as int? ?? json['active_signals'] as int? ?? 0,
      activeEmergencies: json['activeEmergencies'] as int? ?? json['active_emergencies'] as int? ?? 0,
      congestedRoads: json['congestedRoads'] as int? ?? json['congested_roads'] as int? ?? 0,
      averageDelaySeconds: json['averageDelaySeconds'] as int? ?? json['average_delay_seconds'] as int? ?? 0,
    );
  }
}

class DashboardState {
  final List<ActiveMission> activeMissions;
  final List<Intersection> intersections;
  final bool isLoading;
  final String? errorMessage;
  final SystemStatus systemStatus;

  const DashboardState({
    this.activeMissions = const [],
    this.intersections = const [],
    this.isLoading = false,
    this.errorMessage,
    this.systemStatus = const SystemStatus(),
  });

  DashboardState copyWith({
    List<ActiveMission>? activeMissions,
    List<Intersection>? intersections,
    bool? isLoading,
    String? errorMessage,
    SystemStatus? systemStatus,
  }) {
    return DashboardState(
      activeMissions: activeMissions ?? this.activeMissions,
      intersections: intersections ?? this.intersections,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      systemStatus: systemStatus ?? this.systemStatus,
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  final MissionRepository _missionRepo;
  final IntersectionRepository _intersectionRepo;
  final PulseApiClient _apiClient;

  DashboardController(this._missionRepo, this._intersectionRepo, this._apiClient)
      : super(const DashboardState());

  Future<void> initialize() async {
    if (state.activeMissions.isNotEmpty) return;
    await refresh();
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
        // The stats may be nested under a 'stats' key or at the top level
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
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  final missionRepo = ref.watch(missionRepositoryProvider);
  final intersectionRepo = ref.watch(intersectionRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  return DashboardController(missionRepo, intersectionRepo, apiClient);
});
