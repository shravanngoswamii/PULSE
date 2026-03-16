import 'package:pulse_ev/features/settings/models/settings_model.dart';
import 'package:pulse_ev/features/settings/services/settings_service.dart';

class SettingsRepository {
  final SettingsService _service;

  SettingsRepository(this._service);

  Future<SettingsModel> getSettings() async {
    return await _service.loadSettings();
  }

  Future<void> saveSettings(SettingsModel settings) async {
    await _service.saveSettings(settings);
  }

  Future<void> resetSettings() async {
    await _service.resetSettings();
  }
}
