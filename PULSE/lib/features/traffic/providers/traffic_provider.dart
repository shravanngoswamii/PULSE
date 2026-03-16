import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_ev/features/traffic/models/traffic_data_model.dart';
import 'package:pulse_ev/features/traffic/services/traffic_api_service.dart';
import 'package:pulse_ev/features/traffic/repositories/traffic_repository.dart';

final trafficApiServiceProvider = Provider<TrafficApiService>((ref) => TrafficApiService());

final trafficRepositoryProvider = Provider<TrafficRepository>((ref) {
  final apiService = ref.watch(trafficApiServiceProvider);
  return TrafficRepository(apiService);
});

final trafficDataProvider = FutureProvider<TrafficDataModel>((ref) async {
  final repository = ref.watch(trafficRepositoryProvider);
  return await repository.getTrafficData();
});
