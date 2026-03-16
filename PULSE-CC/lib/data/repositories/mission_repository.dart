import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/active_mission.dart';
import '../models/emergency_vehicle.dart';

abstract class MissionRepository {
  Future<List<ActiveMission>> getActiveMissions();
  Future<ActiveMission?> getMissionById(String id);
  Stream<ActiveMission> watchMission(String id);
}

class MockMissionRepository implements MissionRepository {
  final List<ActiveMission> _mockMissions = [
    ActiveMission(
      id: 'M-001',
      vehicle: const EmergencyVehicle(
        id: 'A-12',
        type: VehicleType.ambulance,
        operator: 'S. Jameson',
        status: VehicleStatus.active,
        currentLat: 41.8781,
        currentLng: -87.6298,
        destinationName: 'City Hospital',
        originName: 'Central Station',
        etaSeconds: 300, // 5 minutes
        distanceKm: 3.8,
        corridorId: 'C-001',
      ),
      routeIntersections: const ['INT-MG', 'INT-CS', 'INT-MS'],
      junctionClearance: const {
        'MG Road': ClearanceStatus.green,
        'C. Square': ClearanceStatus.green,
        'Market St': ClearanceStatus.pending,
      },
      startTime: DateTime.now().subtract(const Duration(minutes: 2)),
      estimatedArrival: DateTime.now().add(const Duration(minutes: 5)),
      status: MissionStatus.active,
      eventLog: [
        MissionEvent(
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          message: 'Mission Started',
          type: EventType.info,
        ),
        MissionEvent(
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          message: 'Signal Priority Activated',
          type: EventType.info,
        ),
      ],
    ),
    ActiveMission(
      id: 'M-002',
      vehicle: const EmergencyVehicle(
        id: 'F-05',
        type: VehicleType.fire,
        operator: 'J. Doe',
        status: VehicleStatus.active,
        currentLat: 41.8750,
        currentLng: -87.6250,
        destinationName: 'Industrial Zone',
        originName: 'Main Station',
        etaSeconds: 420, // 7 minutes
        distanceKm: 5.2,
      ),
      routeIntersections: const ['INT-MAIN', 'INT-IND'],
      junctionClearance: const {},
      startTime: DateTime.now().subtract(const Duration(minutes: 5)),
      estimatedArrival: DateTime.now().add(const Duration(minutes: 7)),
      status: MissionStatus.active,
      eventLog: const [],
    ),
  ];

  @override
  Future<List<ActiveMission>> getActiveMissions() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockMissions;
  }

  @override
  Future<ActiveMission?> getMissionById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockMissions.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<ActiveMission> watchMission(String id) async* {
    while (true) {
      final mission = await getMissionById(id);
      if (mission != null) yield mission;
      await Future.delayed(const Duration(seconds: 3));
    }
  }
}

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return MockMissionRepository();
});
