import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/intersection.dart';
import '../../data/models/emergency_vehicle.dart';
import '../../data/models/active_mission.dart';
import '../../data/repositories/intersection_repository.dart';
import '../../data/repositories/mission_repository.dart';

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
  final String intersectionId;

  IntersectionController({
    required IntersectionRepository intersectionRepo,
    required MissionRepository missionRepo,
    required this.intersectionId,
  })  : _intersectionRepo = intersectionRepo,
        _missionRepo = missionRepo,
        super(IntersectionControlState()) {
    initialize();
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
}

final intersectionControllerProvider = StateNotifierProvider.family<
    IntersectionController, IntersectionControlState, String>((ref, id) {
  final intersectionRepo = ref.watch(intersectionRepositoryProvider);
  final missionRepo = ref.watch(missionRepositoryProvider);
  return IntersectionController(
    intersectionRepo: intersectionRepo,
    missionRepo: missionRepo,
    intersectionId: id,
  );
});
