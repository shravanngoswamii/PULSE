import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/intersection.dart';
import '../sources/remote/pulse_api_client.dart';
import '../../core/constants/api_constants.dart';

abstract class IntersectionRepository {
  Future<List<Intersection>> getIntersections();
  Future<Intersection?> getIntersectionById(String id);
  Future<void> forceSignal(String id, SignalPhase phase);
  Future<void> restoreAutomatic(String id);
  Stream<Intersection> watchIntersection(String id);
}

class ApiIntersectionRepository implements IntersectionRepository {
  final PulseApiClient _apiClient;

  ApiIntersectionRepository(this._apiClient);

  @override
  Future<List<Intersection>> getIntersections() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.intersections);
      if (response.statusCode == 200) {
        final data = response.data;
        final List items = data is List
            ? data
            : (data['intersections'] as List? ?? data['items'] as List? ?? []);
        return items
            .map((json) => Intersection.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Intersection?> getIntersectionById(String id) async {
    try {
      final response =
          await _apiClient.dio.get('${ApiConstants.intersections}/$id');
      if (response.statusCode == 200) {
        return Intersection.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> forceSignal(String id, SignalPhase phase) async {
    await _apiClient.dio.post(
      '${ApiConstants.intersections}/$id/force-signal',
      queryParameters: {'phase': phase.name},
    );
  }

  @override
  Future<void> restoreAutomatic(String id) async {
    await _apiClient.dio.post('${ApiConstants.intersections}/$id/restore');
  }

  @override
  Stream<Intersection> watchIntersection(String id) async* {
    while (true) {
      final intersection = await getIntersectionById(id);
      if (intersection != null) yield intersection;
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}

final intersectionRepositoryProvider =
    Provider<IntersectionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiIntersectionRepository(apiClient);
});
