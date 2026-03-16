import 'package:pulse_ev/features/mission/models/hospital_model.dart';
import 'package:pulse_ev/features/mission/services/mission_api_service.dart';

class MissionRepository {
  final MissionApiService _apiService;

  MissionRepository(this._apiService);

  Future<List<HospitalModel>> getHospitals(double lat, double lng) async {
    return await _apiService.getHospitals(lat, lng);
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
    return await _apiService.startMission(
      vehicleId: vehicleId,
      destLat: destLat,
      destLng: destLng,
      destName: destName,
      incidentType: incidentType,
      priority: priority,
      originLat: originLat,
      originLng: originLng,
    );
  }

  Future<void> endMission(String missionId) async {
    await _apiService.endMission(missionId);
  }

  Future<Map<String, dynamic>> pingGPS(String missionId, double lat, double lng) async {
    return await _apiService.pingGPS(missionId, lat, lng);
  }
}
