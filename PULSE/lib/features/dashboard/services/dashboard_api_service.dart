import 'package:pulse_ev/core/network/api_client.dart';
import 'package:pulse_ev/features/dashboard/models/dashboard_model.dart';

class DashboardApiService {
  final ApiClient _apiClient;

  DashboardApiService(this._apiClient);

  Future<DashboardModel> getDashboardData() async {
    final response = await _apiClient.get('/driver/dashboard');
    return DashboardModel.fromJson(response.data as Map<String, dynamic>);
  }
}
