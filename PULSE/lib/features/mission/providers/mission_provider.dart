import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_ev/features/settings/providers/settings_provider.dart';
import 'package:pulse_ev/features/mission/models/hospital_model.dart';
import 'package:pulse_ev/features/mission/models/mission_model.dart';
import 'package:pulse_ev/features/mission/repositories/mission_repository.dart';
import 'package:pulse_ev/features/mission/services/mission_api_service.dart';

// Providers
final missionApiServiceProvider = Provider<MissionApiService>((ref) => MissionApiService());

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  final apiService = ref.watch(missionApiServiceProvider);
  return MissionRepository(apiService);
});

final hospitalsProvider = FutureProvider<List<HospitalModel>>((ref) async {
  final repository = ref.watch(missionRepositoryProvider);
  return await repository.getHospitals();
});

// Mission State Notifier
class MissionNotifier extends StateNotifier<MissionModel?> {
  final MissionRepository _repository;
  final Ref _ref;
  Timer? _progressTimer;

  MissionNotifier(this._repository, this._ref) : super(null);

  Future<void> startMission(String type, String priority, HospitalModel hospital) async {
    final mission = await _repository.startMission(type, priority, hospital);
    state = mission;
    _startSimulation();
  }

  void _startSimulation() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (state == null || state!.status != MissionStatus.active) {
        timer.cancel();
        return;
      }

      final currentDistance = state!.distance;
      if (currentDistance <= 0.1) {
        state = state!.copyWith(
          distance: 0.0,
          eta: "0 min",
          status: MissionStatus.completed,
        );
        timer.cancel();
        return;
      }

      // Simulate progress
      final newDistance = (currentDistance - 0.2).clamp(0.0, double.infinity);
      final newEta = "${(newDistance * 2).toInt() + 1} min";
      
      final settings = _ref.read(settingsProvider);
      final signalsClearedIncrement = (settings.autoSignalOverride && timer.tick % 3 == 0) ? 1 : 0;

      state = state!.copyWith(
        distance: newDistance,
        eta: newEta,
        signalsCleared: state!.signalsCleared + signalsClearedIncrement,
      );
    });
  }

  Future<void> endMission() async {
    if (state != null) {
      await _repository.endMission(state!.missionId);
      _progressTimer?.cancel();
      state = null;
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }
}

final missionProvider = StateNotifierProvider<MissionNotifier, MissionModel?>((ref) {
  final repository = ref.watch(missionRepositoryProvider);
  return MissionNotifier(repository, ref);
});
