import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_ev/features/dashboard/models/dashboard_model.dart';
import 'package:pulse_ev/features/dashboard/services/dashboard_api_service.dart';

final dashboardApiServiceProvider = Provider<DashboardApiService>((ref) => DashboardApiService());

final dashboardProvider = FutureProvider<DashboardModel>((ref) async {
  final apiService = ref.watch(dashboardApiServiceProvider);
  return await apiService.getDashboardData();
});
