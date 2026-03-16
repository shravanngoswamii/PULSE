import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/active_mission.dart';
import '../models/emergency_vehicle.dart';
import '../sources/remote/pulse_api_client.dart';
import '../../core/constants/api_constants.dart';

abstract class MissionRepository {
  Future<List<ActiveMission>> getActiveMissions();
  Future<ActiveMission?> getMissionById(String id);
  Stream<ActiveMission> watchMission(String id);
}

class ApiMissionRepository implements MissionRepository {
  final PulseApiClient _apiClient;

  ApiMissionRepository(this._apiClient);

  @override
  Future<List<ActiveMission>> getActiveMissions() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.missions,
        queryParameters: {'status': 'active'},
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final List items = data is List ? data : (data['missions'] as List? ?? data['items'] as List? ?? []);
        return items.map((json) => _parseMission(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<ActiveMission?> getMissionById(String id) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.missions}/$id');
      if (response.statusCode == 200) {
        return _parseMission(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<ActiveMission> watchMission(String id) async* {
    while (true) {
      final mission = await getMissionById(id);
      if (mission != null) yield mission;
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  ActiveMission _parseMission(Map<String, dynamic> json) {
    // Parse vehicle - may be nested or flat
    final vehicleJson = json['vehicle'] as Map<String, dynamic>? ?? json;
    final vehicle = EmergencyVehicle(
      id: (vehicleJson['id'] ?? vehicleJson['vehicle_id'] ?? '') as String,
      type: _parseVehicleType(vehicleJson['type'] as String? ?? 'ambulance'),
      operator: (vehicleJson['operator'] ?? vehicleJson['driver'] ?? '') as String,
      status: _parseVehicleStatus(vehicleJson['status'] as String? ?? 'active'),
      currentLat: _toDouble(vehicleJson['currentLat'] ?? vehicleJson['current_lat'] ?? vehicleJson['lat'] ?? 0),
      currentLng: _toDouble(vehicleJson['currentLng'] ?? vehicleJson['current_lng'] ?? vehicleJson['lng'] ?? 0),
      destinationName: (vehicleJson['destinationName'] ?? vehicleJson['destination_name'] ?? vehicleJson['destination'] ?? '') as String,
      originName: (vehicleJson['originName'] ?? vehicleJson['origin_name'] ?? vehicleJson['origin'] ?? '') as String,
      etaSeconds: (vehicleJson['etaSeconds'] ?? vehicleJson['eta_seconds'] ?? vehicleJson['eta'] ?? 0) as int,
      distanceKm: _toDouble(vehicleJson['distanceKm'] ?? vehicleJson['distance_km'] ?? vehicleJson['distance'] ?? 0),
      corridorId: vehicleJson['corridorId'] as String? ?? vehicleJson['corridor_id'] as String?,
    );

    // Parse junction clearance
    final jcRaw = json['junctionClearance'] ?? json['junction_clearance'] ?? {};
    final Map<String, ClearanceStatus> junctionClearance = {};
    if (jcRaw is Map) {
      jcRaw.forEach((key, value) {
        junctionClearance[key as String] = _parseClearanceStatus(value.toString());
      });
    }

    // Parse event log
    final eventsRaw = json['eventLog'] ?? json['event_log'] ?? json['events'] ?? [];
    final List<MissionEvent> eventLog = (eventsRaw as List).map((e) {
      final ev = e as Map<String, dynamic>;
      return MissionEvent(
        timestamp: DateTime.tryParse(ev['timestamp'] as String? ?? '') ?? DateTime.now(),
        message: (ev['message'] ?? '') as String,
        type: _parseEventType(ev['type'] as String? ?? 'info'),
        subtitle: ev['subtitle'] as String?,
      );
    }).toList();

    return ActiveMission(
      id: (json['id'] ?? json['mission_id'] ?? '') as String,
      vehicle: vehicle,
      routeIntersections: List<String>.from(json['routeIntersections'] ?? json['route_intersections'] ?? []),
      junctionClearance: junctionClearance,
      startTime: DateTime.tryParse((json['startTime'] ?? json['start_time'] ?? '').toString()) ?? DateTime.now(),
      estimatedArrival: DateTime.tryParse((json['estimatedArrival'] ?? json['estimated_arrival'] ?? '').toString()) ?? DateTime.now().add(const Duration(minutes: 10)),
      status: _parseMissionStatus(json['status'] as String? ?? 'active'),
      eventLog: eventLog,
    );
  }

  double _toDouble(dynamic v) => (v is num) ? v.toDouble() : 0.0;

  VehicleType _parseVehicleType(String s) {
    switch (s.toLowerCase()) {
      case 'ambulance': return VehicleType.ambulance;
      case 'fire': return VehicleType.fire;
      case 'police': return VehicleType.police;
      default: return VehicleType.ambulance;
    }
  }

  VehicleStatus _parseVehicleStatus(String s) {
    switch (s.toLowerCase()) {
      case 'active': return VehicleStatus.active;
      case 'standby': return VehicleStatus.standby;
      case 'completed': return VehicleStatus.completed;
      default: return VehicleStatus.active;
    }
  }

  MissionStatus _parseMissionStatus(String s) {
    switch (s.toLowerCase()) {
      case 'active': return MissionStatus.active;
      case 'completed': return MissionStatus.completed;
      case 'cancelled': return MissionStatus.cancelled;
      default: return MissionStatus.active;
    }
  }

  ClearanceStatus _parseClearanceStatus(String s) {
    switch (s.toLowerCase()) {
      case 'green': return ClearanceStatus.green;
      case 'pending': return ClearanceStatus.pending;
      case 'cleared': return ClearanceStatus.cleared;
      default: return ClearanceStatus.pending;
    }
  }

  EventType _parseEventType(String s) {
    switch (s.toLowerCase()) {
      case 'info': return EventType.info;
      case 'warning': return EventType.warning;
      case 'cleared': return EventType.cleared;
      case 'rerouted': return EventType.rerouted;
      default: return EventType.info;
    }
  }
}

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiMissionRepository(apiClient);
});
