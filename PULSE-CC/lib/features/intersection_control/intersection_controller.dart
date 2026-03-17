import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/intersection.dart';
import '../../data/models/emergency_vehicle.dart';
import '../../data/models/active_mission.dart';
import '../../data/repositories/intersection_repository.dart';
import '../../data/repositories/mission_repository.dart';
import '../../data/sources/remote/pulse_websocket.dart';

class IntersectionControlState {
  final Intersection? intersection;
  final String selectedLane;
  final bool isLoading;
  final bool hasActiveEmergency;
  final EmergencyVehicle? approachingVehicle;
  final String? successMessage;
  final String? errorMessage;

  IntersectionControlState({
    this.intersection,
    this.selectedLane = 'NORTH',
    this.isLoading = false,
    this.hasActiveEmergency = false,
    this.approachingVehicle,
    this.successMessage,
    this.errorMessage,
  });

  IntersectionControlState copyWith({
    Intersection? intersection,
    String? selectedLane,
    bool? isLoading,
    bool? hasActiveEmergency,
    EmergencyVehicle? approachingVehicle,
    String? successMessage,
    String? errorMessage,
  }) {
    return IntersectionControlState(
      intersection: intersection ?? this.intersection,
      selectedLane: selectedLane ?? this.selectedLane,
      isLoading: isLoading ?? this.isLoading,
      hasActiveEmergency: hasActiveEmergency ?? this.hasActiveEmergency,
      approachingVehicle: approachingVehicle ?? this.approachingVehicle,
      successMessage: successMessage ?? this.successMessage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class IntersectionController
    extends StateNotifier<IntersectionControlState> {
  final IntersectionRepository _intersectionRepo;
  final MissionRepository _missionRepo;
  final PulseWebSocket _webSocket;
  final String intersectionId;
  StreamSubscription? _wsSub;

  IntersectionController({
    required IntersectionRepository intersectionRepo,
    required MissionRepository missionRepo,
    required PulseWebSocket webSocket,
    required this.intersectionId,
  })  : _intersectionRepo = intersectionRepo,
        _missionRepo = missionRepo,
        _webSocket = webSocket,
        super(IntersectionControlState()) {
    initialize();
    _startWebSocket();
  }

  void _startWebSocket() async {
    await _webSocket.connect();
    _wsSub = _webSocket.eventStream.listen((data) {
      final event = data['event'] as String? ?? '';
      switch (event) {
        case 'signal_change':
          if (data['intersection_id'] == intersectionId) {
            _refreshIntersection();
          }
          break;
        case 'mission_started':
          // Check if our intersection is on the new mission's route
          final route = data['route'] as List?;
          if (route != null && route.contains(intersectionId)) {
            _refreshEmergencyStatus();
          }
          break;
        case 'mission_completed':
          _refreshEmergencyStatus();
          break;
        case 'vehicle_position':
          // Update approaching vehicle ETA
          _handleVehiclePosition(data);
          break;
      }
    });
  }

  Future<void> _refreshIntersection() async {
    final updated = await _intersectionRepo.getIntersectionById(intersectionId);
    if (updated != null && mounted) {
      state = state.copyWith(intersection: updated);
    }
  }

  Future<void> _refreshEmergencyStatus() async {
    final activeMissions = await _missionRepo.getActiveMissions();
    final hasEmergency = activeMissions.any((m) => m.status == MissionStatus.active);
    final ambulance = activeMissions
        .where((m) => m.vehicle.type == VehicleType.ambulance)
        .map((m) => m.vehicle)
        .firstOrNull;

    if (mounted) {
      state = state.copyWith(
        hasActiveEmergency: hasEmergency,
        approachingVehicle: ambulance ?? (activeMissions.isNotEmpty ? activeMissions.first.vehicle : null),
      );
    }
  }

  void _handleVehiclePosition(Map<String, dynamic> data) {
    if (state.approachingVehicle == null) return;
    final vehicleId = data['vehicle_id'] as String?;
    if (vehicleId != state.approachingVehicle?.id) return;

    final etaMin = (data['eta_minutes'] as num?)?.toDouble();
    if (etaMin != null && mounted) {
      state = state.copyWith(
        approachingVehicle: state.approachingVehicle!.copyWith(
          etaSeconds: (etaMin * 60).toInt(),
        ),
      );
    }
  }

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      final intersection =
          await _intersectionRepo.getIntersectionById(intersectionId);
      final activeMissions = await _missionRepo.getActiveMissions();

      final hasEmergency =
          activeMissions.any((m) => m.status == MissionStatus.active);

      final ambulance = activeMissions
              .where((m) => m.vehicle.type == VehicleType.ambulance)
              .isEmpty
          ? null
          : activeMissions
              .where((m) => m.vehicle.type == VehicleType.ambulance)
              .first
              .vehicle;

      state = state.copyWith(
        intersection: intersection,
        hasActiveEmergency: hasEmergency,
        approachingVehicle: ambulance,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load intersection data',
        isLoading: false,
      );
    }
  }

  void selectLane(String lane) {
    state = state.copyWith(selectedLane: lane);
  }

  Future<void> forceGreen() async {
    try {
      await _intersectionRepo.forceSignal(intersectionId, SignalPhase.green);
      _showSuccess('Signal forced to GREEN for ${state.selectedLane} lane');
      // Refresh intersection data
      final updated =
          await _intersectionRepo.getIntersectionById(intersectionId);
      if (updated != null) {
        state = state.copyWith(intersection: updated);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to force green signal');
    }
  }

  Future<void> forceRed() async {
    try {
      await _intersectionRepo.forceSignal(intersectionId, SignalPhase.red);
      _showSuccess('Signal forced to RED for ${state.selectedLane} lane');
      final updated =
          await _intersectionRepo.getIntersectionById(intersectionId);
      if (updated != null) {
        state = state.copyWith(intersection: updated);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to force red signal');
    }
  }

  Future<void> restoreAutomatic() async {
    try {
      await _intersectionRepo.restoreAutomatic(intersectionId);
      _showSuccess('Automatic control restored');
      final updated =
          await _intersectionRepo.getIntersectionById(intersectionId);
      if (updated != null) {
        state = state.copyWith(intersection: updated);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to restore auto control');
    }
  }

  void activateGreenCorridor() {
    if (state.approachingVehicle != null) {
      forceGreen();
    }
    _showSuccess(
        'GREEN CORRIDOR activated for ${state.approachingVehicle?.id ?? "Emergency Vehicle"}');
  }

  void _showSuccess(String message) {
    state = state.copyWith(successMessage: message);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        state = state.copyWith(successMessage: null);
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }
}

final intersectionControllerProvider = StateNotifierProvider.family<
    IntersectionController, IntersectionControlState, String>((ref, id) {
  final intersectionRepo = ref.watch(intersectionRepositoryProvider);
  final missionRepo = ref.watch(missionRepositoryProvider);
  final webSocket = ref.watch(websocketProvider);
  return IntersectionController(
    intersectionRepo: intersectionRepo,
    missionRepo: missionRepo,
    webSocket: webSocket,
    intersectionId: id,
  );
});
