import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/active_mission.dart';
import '../../data/models/intersection.dart';
import '../../data/repositories/mission_repository.dart';
import '../../data/repositories/intersection_repository.dart';

class SystemStatus {
  final int activeSignals;
  final int activeEmergencies;
  final int congestedRoads;
  final int averageDelaySeconds;

  const SystemStatus({
    this.activeSignals = 128,
    this.activeEmergencies = 2,
    this.congestedRoads = 5,
    this.averageDelaySeconds = 14,
  });
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

  DashboardController(this._missionRepo, this._intersectionRepo)
      : super(const DashboardState());

  Future<void> initialize() async {
    if (state.activeMissions.isNotEmpty) return;
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final missions = await _missionRepo.getActiveMissions();
      final intersections = await _intersectionRepo.getIntersections();
      state = state.copyWith(
        activeMissions: missions,
        intersections: intersections,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load dashboard data',
      );
    }
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
  return DashboardController(missionRepo, intersectionRepo);
});
