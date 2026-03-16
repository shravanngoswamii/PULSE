import 'package:pulse_ev/core/network/api_client.dart';
import 'package:pulse_ev/features/mission/models/hospital_model.dart';

class MissionApiService {
  final ApiClient _apiClient;

  MissionApiService(this._apiClient);

  Future<List<HospitalModel>> getHospitals(double lat, double lng) async {
    final response = await _apiClient.get(
      '/driver/nearby-hospitals',
      queryParameters: {'lat': lat, 'lng': lng},
    );
    final List data = response.data is List ? response.data : response.data['hospitals'] ?? [];
    return data.map((json) => HospitalModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> startMission({
    required String vehicleId,
    required double destLat,
    required double destLng,
    required String destName,
    required String incidentType,
    required String priority,
    required double originLat,
    required double originLng,
  }) async {
    final response = await _apiClient.post(
      '/driver/mission/start',
      data: {
        'vehicle_id': vehicleId,
        'destination_lat': destLat,
        'destination_lng': destLng,
        'destination_name': destName,
        'incident_type': incidentType,
        'priority': priority,
        'origin_lat': originLat,
        'origin_lng': originLng,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> endMission(String missionId) async {
    await _apiClient.post(
      '/driver/mission/end',
      data: {'mission_id': missionId},
    );
  }

  Future<Map<String, dynamic>> pingGPS(String missionId, double lat, double lng) async {
    final response = await _apiClient.post(
      '/driver/mission/ping',
      data: {
        'mission_id': missionId,
        'current_lat': lat,
        'current_lng': lng,
      },
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }
}
