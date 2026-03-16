import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/intersection.dart';

abstract class IntersectionRepository {
  Future<List<Intersection>> getIntersections();
  Future<Intersection?> getIntersectionById(String id);
  Future<void> forceSignal(String id, SignalPhase phase);
  Future<void> restoreAutomatic(String id);
  Stream<Intersection> watchIntersection(String id);
}

class MockIntersectionRepository implements IntersectionRepository {
  final List<Intersection> _mockIntersections = [
    const Intersection(
      id: 'INT-001',
      name: 'Lexington & 52nd Junction',
      district: 'Harbor District',
      lat: 41.8820,
      lng: -87.6278,
      signalMode: SignalMode.automatic,
      currentPhase: SignalPhase.green,
      vehiclesWaiting: 12,
      avgDelaySeconds: 18,
      congestionLevel: CongestionLevel.moderate,
    ),
    const Intersection(
      id: 'INT-002',
      name: 'Madison Ave Junction',
      district: 'Central District',
      lat: 41.8810,
      lng: -87.6300,
      signalMode: SignalMode.manual,
      currentPhase: SignalPhase.red,
      vehiclesWaiting: 24,
      avgDelaySeconds: 35,
      congestionLevel: CongestionLevel.high,
    ),
  ];

  @override
  Future<List<Intersection>> getIntersections() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockIntersections;
  }

  @override
  Future<Intersection?> getIntersectionById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockIntersections.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> forceSignal(String id, SignalPhase phase) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<void> restoreAutomatic(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Stream<Intersection> watchIntersection(String id) async* {
    while (true) {
      final intersection = await getIntersectionById(id);
      if (intersection != null) yield intersection;
      await Future.delayed(const Duration(seconds: 2));
    }
  }
}

final intersectionRepositoryProvider = Provider<IntersectionRepository>((ref) {
  return MockIntersectionRepository();
});
