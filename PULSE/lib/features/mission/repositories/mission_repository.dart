import 'package:pulse_ev/features/mission/models/hospital_model.dart';
import 'package:pulse_ev/features/mission/models/mission_model.dart';
import 'package:pulse_ev/features/mission/services/mission_api_service.dart';

class MissionRepository {
  final MissionApiService _apiService;

  MissionRepository(this._apiService);

  Future<List<HospitalModel>> getHospitals() async {
    return await _apiService.getHospitals();
  }

  Future<MissionModel> startMission(String type, String priority, HospitalModel hospital) async {
    return await _apiService.startMission(type, priority, hospital);
  }

  Future<void> endMission(String missionId) async {
    await _apiService.endMission(missionId);
  }
}
