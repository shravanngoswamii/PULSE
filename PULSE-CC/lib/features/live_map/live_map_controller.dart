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

    // Subscribe to WebSocket for real-time updates
    await _webSocket.connect();
    _wsSub = _webSocket.eventStream.listen((data) {
      final event = data['event'] as String? ?? data['type'] as String? ?? '';
      switch (event) {
        case 'vehicle_position':
          _handleVehicleUpdate(data);
          break;
        case 'mission_started':
        case 'mission_completed':
          _refreshData();
          break;
        case 'signal_change':
          _handleSignalChange(data);
          break;
      }
    });
  }

  Future<void> _refreshData() async {
    try {
      final missions = await _missionRepo.getActiveMissions();
      final intersections = await _intersectionRepo.getIntersections();
      state = state.copyWith(activeMissions: missions, intersections: intersections);
    } catch (_) {}
  }

  void _handleVehicleUpdate(Map<String, dynamic> data) {
    final vehicleId = data['vehicle_id'] as String? ?? data['vehicleId'] as String?;
    if (vehicleId == null) return;

    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    final updatedMissions = state.activeMissions.map((mission) {
      if (mission.vehicle.id == vehicleId) {
        final etaMin = (data['eta_minutes'] as num?)?.toDouble();
        return mission.copyWith(
          vehicle: mission.vehicle.copyWith(
            currentLat: lat,
            currentLng: lng,
            etaSeconds: etaMin != null ? (etaMin * 60).toInt() : null,
          ),
        );
      }
      return mission;
    }).toList();

    state = state.copyWith(activeMissions: updatedMissions);
  }

  void _handleSignalChange(Map<String, dynamic> data) {
    final iid = data['intersection_id'] as String?;
    if (iid == null) return;
    final phase = data['phase'] as String? ?? 'green';
    final mode = data['mode'] as String? ?? 'automatic';

    final updated = state.intersections.map((i) {
      if (i.id == iid) {
        return i.copyWith(
          signalMode: SignalMode.values.firstWhere((e) => e.name == mode, orElse: () => SignalMode.automatic),
          currentPhase: SignalPhase.values.firstWhere((e) => e.name == phase, orElse: () => SignalPhase.green),
        );
      }
      return i;
    }).toList();
    state = state.copyWith(intersections: updated);
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
