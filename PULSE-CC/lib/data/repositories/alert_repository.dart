import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/traffic_alert.dart';
import '../sources/remote/pulse_api_client.dart';
import '../../core/constants/api_constants.dart';

abstract class AlertRepository {
  Future<List<TrafficAlert>> getAlerts();
  Future<List<TrafficAlert>> getAlertsByType(AlertType type);
  Future<void> createAlert(TrafficAlert alert);
  Future<void> clearAlert(String id);
  Stream<List<TrafficAlert>> watchAlerts();
}

class ApiAlertRepository implements AlertRepository {
  final PulseApiClient _apiClient;

  ApiAlertRepository(this._apiClient);

  @override
  Future<List<TrafficAlert>> getAlerts() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.alerts);
      if (response.statusCode == 200) {
        final data = response.data;
        final List items = data is List
            ? data
            : (data['alerts'] as List? ?? data['items'] as List? ?? []);
        return items
            .map((json) => TrafficAlert.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<TrafficAlert>> getAlertsByType(AlertType type) async {
    final alerts = await getAlerts();
    return alerts.where((a) => a.type == type).toList();
  }

  @override
  Future<void> createAlert(TrafficAlert alert) async {
    await _apiClient.dio.post(
      ApiConstants.alerts,
      data: alert.toJson(),
    );
  }

  @override
  Future<void> clearAlert(String id) async {
    await _apiClient.dio.post('${ApiConstants.alerts}/$id/clear');
  }

  @override
  Stream<List<TrafficAlert>> watchAlerts() async* {
    while (true) {
      yield await getAlerts();
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiAlertRepository(apiClient);
});
