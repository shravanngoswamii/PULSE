import 'package:pulse_ev/features/traffic/models/traffic_data_model.dart';
import 'package:pulse_ev/features/traffic/services/traffic_api_service.dart';

class TrafficRepository {
  final TrafficApiService _apiService;

  TrafficRepository(this._apiService);

  Future<TrafficDataModel> getTrafficData() async {
    return await _apiService.getTrafficData();
  }
}
