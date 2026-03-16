import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/active_mission.dart';
import '../../data/models/intersection.dart';
import '../../data/repositories/mission_repository.dart';
import '../../data/repositories/intersection_repository.dart';
import '../../data/sources/remote/pulse_websocket.dart';

enum PulseMapStyle { streets, satellite, dark }

class LiveMapState {
  final List<ActiveMission> activeMissions;
  final List<Intersection> intersections;
  final Intersection? selectedIntersection;
  final bool showSignals;
  final bool showEmergencyVehicles;
  final bool isLoading;
  final PulseMapStyle mapStyle;

  const LiveMapState({
    this.activeMissions = const [],
    this.intersections = const [],
    this.selectedIntersection,
    this.showSignals = true,
    this.showEmergencyVehicles = true,
    this.isLoading = false,
    this.mapStyle = PulseMapStyle.streets,
  });

  LiveMapState copyWith({
    List<ActiveMission>? activeMissions,
    List<Intersection>? intersections,
    Intersection? selectedIntersection,
    bool clearSelection = false,
    bool? showSignals,
    bool? showEmergencyVehicles,
    bool? isLoading,
    PulseMapStyle? mapStyle,
  }) {
    return LiveMapState(
      activeMissions: activeMissions ?? this.activeMissions,
      intersections: intersections ?? this.intersections,
      selectedIntersection:
          clearSelection ? null : (selectedIntersection ?? this.selectedIntersection),
      showSignals: showSignals ?? this.showSignals,
      showEmergencyVehicles:
          showEmergencyVehicles ?? this.showEmergencyVehicles,
      isLoading: isLoading ?? this.isLoading,
      mapStyle: mapStyle ?? this.mapStyle,
    );
  }
}

class LiveMapController extends StateNotifier<LiveMapState> {
  final MissionRepository _missionRepo;
  final IntersectionRepository _intersectionRepo;
  final PulseWebSocket _webSocket;
  StreamSubscription? _wsSub;

  LiveMapController(
    this._missionRepo,
    this._intersectionRepo,
    this._webSocket,
  ) : super(const LiveMapState());

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

    // Subscribe to WebSocket for real-time vehicle position updates
    await _webSocket.connect();
    _wsSub = _webSocket.onEvent('vehicle_update').listen((data) {
      _handleVehicleUpdate(data);
    });
  }

  void _handleVehicleUpdate(Map<String, dynamic> data) {
    // Update the mission's vehicle position in-place
    final vehicleId = data['vehicle_id'] as String? ?? data['vehicleId'] as String?;
    if (vehicleId == null) return;

    final lat = data['lat'] as num?;
    final lng = data['lng'] as num?;
    if (lat == null || lng == null) return;

    final updatedMissions = state.activeMissions.map((mission) {
      if (mission.vehicle.id == vehicleId) {
        return mission.copyWith(
          vehicle: mission.vehicle.copyWith(
            currentLat: lat.toDouble(),
            currentLng: lng.toDouble(),
          ),
        );
      }
      return mission;
    }).toList();

    state = state.copyWith(activeMissions: updatedMissions);
  }

  void toggleSignalLayer() {
    state = state.copyWith(showSignals: !state.showSignals);
  }

  void toggleVehicleLayer() {
    state = state.copyWith(
        showEmergencyVehicles: !state.showEmergencyVehicles);
  }

  void selectIntersection(Intersection? intersection) {
    state = state.copyWith(selectedIntersection: intersection);
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }
}

final liveMapControllerProvider =
    StateNotifierProvider<LiveMapController, LiveMapState>((ref) {
  final missionRepo = ref.watch(missionRepositoryProvider);
  final intersectionRepo = ref.watch(intersectionRepositoryProvider);
  final webSocket = ref.watch(websocketProvider);
  return LiveMapController(missionRepo, intersectionRepo, webSocket);
});
