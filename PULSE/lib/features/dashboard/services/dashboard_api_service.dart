import 'package:pulse_ev/features/dashboard/models/dashboard_model.dart';

class DashboardApiService {
  Future<DashboardModel> getDashboardData() async {
    await Future.delayed(const Duration(milliseconds: 600));

    return DashboardModel(
      vehicleName: "Ambulance A-12",
      vehicleId: "A-12",
      vehicleStatus: "AVAILABLE",
      station: "Central Station",
      trafficDensity: "Medium",
      nearbyIncidents: 2,
      recentMissions: [
        RecentMission(from: "Station", to: "City Hospital", durationMinutes: 12),
        RecentMission(from: "Downtown", to: "Trauma Center", durationMinutes: 9),
      ],
    );
  }
}
