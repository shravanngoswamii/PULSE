import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/active_mission.dart';
import '../../data/models/intersection.dart';
import '../../data/repositories/mission_repository.dart';
import '../../data/repositories/intersection_repository.dart';

class LiveMapState {
  final List<ActiveMission> activeMissions;
  final List<Intersection> intersections;
  final Intersection? selectedIntersection;
  final bool showSignals;
  final bool showEmergencyVehicles;
  final bool isLoading;
  final MapType mapType;

  const LiveMapState({
    this.activeMissions = const [],
    this.intersections = const [],
    this.selectedIntersection,
    this.showSignals = true,
    this.showEmergencyVehicles = true,
    this.isLoading = false,
    this.mapType = MapType.normal,
  });

  LiveMapState copyWith({
    List<ActiveMission>? activeMissions,
    List<Intersection>? intersections,
    Intersection? selectedIntersection,
    bool clearSelection = false,
    bool? showSignals,
    bool? showEmergencyVehicles,
    bool? isLoading,
    MapType? mapType,
  }) {
    return LiveMapState(
      activeMissions: activeMissions ?? this.activeMissions,
      intersections: intersections ?? this.intersections,
      selectedIntersection: clearSelection ? null : (selectedIntersection ?? this.selectedIntersection),
      showSignals: showSignals ?? this.showSignals,
      showEmergencyVehicles: showEmergencyVehicles ?? this.showEmergencyVehicles,
      isLoading: isLoading ?? this.isLoading,
      mapType: mapType ?? this.mapType,
    );
  }
}

class LiveMapController extends StateNotifier<LiveMapState> {
  final MissionRepository _missionRepo;
  final IntersectionRepository _intersectionRepo;

  LiveMapController(this._missionRepo, this._intersectionRepo)
      : super(const LiveMapState());

  Future<void> initialize() async {
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
      state = state.copyWith(isLoading: false);
    }
  }

  void toggleSignalLayer() {
    state = state.copyWith(showSignals: !state.showSignals);
  }

  void toggleVehicleLayer() {
    state = state.copyWith(showEmergencyVehicles: !state.showEmergencyVehicles);
  }

  void selectIntersection(Intersection? intersection) {
    state = state.copyWith(selectedIntersection: intersection);
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }
}

final liveMapControllerProvider =
    StateNotifierProvider<LiveMapController, LiveMapState>((ref) {
  final missionRepo = ref.watch(missionRepositoryProvider);
  final intersectionRepo = ref.watch(intersectionRepositoryProvider);
  return LiveMapController(missionRepo, intersectionRepo);
});
