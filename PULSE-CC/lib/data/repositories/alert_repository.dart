import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/traffic_alert.dart';

abstract class AlertRepository {
  Future<List<TrafficAlert>> getAlerts();
  Future<List<TrafficAlert>> getAlertsByType(AlertType type);
  Future<void> clearAlert(String id);
  Stream<List<TrafficAlert>> watchAlerts(); // changed to List stream
}

class MockAlertRepository implements AlertRepository {
  final List<TrafficAlert> _mockAlerts = [
    TrafficAlert(
      id: 'ALT-001',
      type: AlertType.accident,
      severity: Severity.high,
      title: 'Accident - MG Road',
      location: 'MG Road Junction',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)), // e.g. 10:32 AM
      isActive: true,
    ),
    TrafficAlert(
      id: 'ALT-002',
      type: AlertType.signalFailure,
      severity: Severity.medium,
      title: 'Signal Failure - Central Square',
      location: 'Central Square',
      timestamp: DateTime.now().subtract(const Duration(minutes: 27)), // e.g. 10:35 AM
      isActive: true,
    ),
    TrafficAlert(
      id: 'ALT-003',
      type: AlertType.emergencyVehicle,
      severity: Severity.low,
      title: 'Emergency Vehicle Approaching',
      location: 'Ambulance [Vehicle ID] A-12',
      vehicleId: 'A-12',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      isActive: true,
    ),
  ];

  @override
  Future<List<TrafficAlert>> getAlerts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockAlerts.where((a) => a.isActive).toList();
  }

  @override
  Future<List<TrafficAlert>> getAlertsByType(AlertType type) async {
    final alerts = await getAlerts();
    return alerts.where((a) => a.type == type).toList();
  }

  @override
  Future<void> clearAlert(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockAlerts.indexWhere((a) => a.id == id);
    if (index != -1) {
      _mockAlerts[index] = TrafficAlert(
        id: _mockAlerts[index].id,
        type: _mockAlerts[index].type,
        severity: _mockAlerts[index].severity,
        title: _mockAlerts[index].title,
        location: _mockAlerts[index].location,
        intersectionId: _mockAlerts[index].intersectionId,
        vehicleId: _mockAlerts[index].vehicleId,
        timestamp: _mockAlerts[index].timestamp,
        isActive: false,
        description: _mockAlerts[index].description,
      );
    }
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
  return MockAlertRepository();
});
