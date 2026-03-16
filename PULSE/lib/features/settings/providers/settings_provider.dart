import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_ev/core/storage/secure_storage.dart';
import 'package:pulse_ev/features/settings/models/settings_model.dart';
import 'package:pulse_ev/features/settings/services/settings_service.dart';
import 'package:pulse_ev/features/settings/repositories/settings_repository.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return SettingsService(storage);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsRepository(service);
});

class SettingsNotifier extends StateNotifier<SettingsModel> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(SettingsModel.defaultSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = await _repository.getSettings();
  }

  Future<void> updateSettings(SettingsModel newSettings) async {
    state = newSettings;
    await _repository.saveSettings(state);
  }

  // Individual toggles
  void toggleMissionAlerts() => updateSettings(state.copyWith(missionAlerts: !state.missionAlerts));
  void toggleTrafficAlerts() => updateSettings(state.copyWith(trafficAlerts: !state.trafficAlerts));
  void toggleSignalAlerts() => updateSettings(state.copyWith(signalPriorityAlerts: !state.signalPriorityAlerts));
  void toggleIncidentNotifications() => updateSettings(state.copyWith(incidentNotifications: !state.incidentNotifications));

  void toggleVoiceGuidance() => updateSettings(state.copyWith(voiceGuidance: !state.voiceGuidance));
  void toggleRouteRecalculation() => updateSettings(state.copyWith(routeRecalculation: !state.routeRecalculation));
  void toggleAvoidTraffic() => updateSettings(state.copyWith(avoidHeavyTraffic: !state.avoidHeavyTraffic));
  void setMapOrientation(String orientation) => updateSettings(state.copyWith(mapOrientation: orientation));

  void setDataSyncMode(String mode) => updateSettings(state.copyWith(dataSyncMode: mode));
  void toggleMapRefresh() => updateSettings(state.copyWith(mapDataRefresh: !state.mapDataRefresh));
  void toggleSimulationMode() => updateSettings(state.copyWith(simulationMode: !state.simulationMode));

  void toggleAutoSignalOverride() => updateSettings(state.copyWith(autoSignalOverride: !state.autoSignalOverride));
  void toggleEmergencySirenSync() => updateSettings(state.copyWith(emergencySirenSync: !state.emergencySirenSync));
  void toggleTrafficAuthorityLink() => updateSettings(state.copyWith(trafficAuthorityLink: !state.trafficAuthorityLink));
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repository);
});
