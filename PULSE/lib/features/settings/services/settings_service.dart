import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pulse_ev/features/settings/models/settings_model.dart';

class SettingsService {
  final FlutterSecureStorage _storage;
  static const String _settingsKey = 'pulse_app_settings';

  SettingsService(this._storage);

  Future<void> saveSettings(SettingsModel settings) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _storage.write(key: _settingsKey, value: jsonEncode(settings.toJson()));
  }

  Future<SettingsModel> loadSettings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final String? data = await _storage.read(key: _settingsKey);
    if (data != null) {
      try {
        return SettingsModel.fromJson(jsonDecode(data));
      } catch (_) {
        return SettingsModel.defaultSettings();
      }
    }
    return SettingsModel.defaultSettings();
  }

  Future<void> resetSettings() async {
    await _storage.delete(key: _settingsKey);
  }
}
