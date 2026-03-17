import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_ev/features/dashboard/models/dashboard_model.dart';
import 'package:pulse_ev/features/dashboard/services/dashboard_api_service.dart';
import 'package:pulse_ev/features/mission/providers/mission_provider.dart';

final dashboardApiServiceProvider = Provider<DashboardApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardApiService(apiClient);
});

final dashboardProvider = FutureProvider<DashboardModel>((ref) async {
  final apiService = ref.watch(dashboardApiServiceProvider);
  final data = await apiService.getDashboardData();

  if (data.activeMission != null) {
    ref.read(missionProvider.notifier).restoreFromBackend(data.activeMission!);
  }

  return data;
});
