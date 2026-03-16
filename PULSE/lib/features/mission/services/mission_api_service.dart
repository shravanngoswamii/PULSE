import 'package:pulse_ev/features/mission/models/hospital_model.dart';
import 'package:pulse_ev/features/mission/models/mission_model.dart';

class MissionApiService {
  Future<List<HospitalModel>> getHospitals() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      HospitalModel(
        name: "City Hospital",
        distance: 4.2,
        eta: "7 min",
        coordinates: [40.7128, -74.0060],
        signalsToOverride: 5,
      ),
      HospitalModel(
        name: "Trauma Center",
        distance: 5.8,
        eta: "10 min",
        coordinates: [40.7200, -74.0100],
        signalsToOverride: 8,
      ),
      HospitalModel(
        name: "Emergency Center",
        distance: 3.1,
        eta: "5 min",
        coordinates: [40.7050, -73.9950],
        signalsToOverride: 4,
      ),
    ];
  }

  Future<MissionModel> startMission(String type, String priority, HospitalModel hospital) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return MissionModel(
      missionId: "MSN_${DateTime.now().millisecondsSinceEpoch}",
      incidentType: type,
      priorityLevel: priority,
      destinationHospital: hospital,
      distance: hospital.distance,
      eta: hospital.eta,
      signalsCleared: 0,
      status: MissionStatus.active,
    );
  }

  Future<void> endMission(String missionId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
