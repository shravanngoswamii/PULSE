import 'package:pulse_ev/features/traffic/models/traffic_data_model.dart';

class TrafficApiService {
  Future<TrafficDataModel> getTrafficData() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return TrafficDataModel(
      trafficDensity: "Moderate",
      blockedRoads: 2,
      avgSignalTime: 18,
      incidents: [
        TrafficIncident(
          title: "Accident",
          location: "MG Road",
          distance: "1.2 km",
          type: "accident",
        ),
        TrafficIncident(
          title: "Roadblock",
          location: "Central Ave",
          distance: "2.4 km",
          type: "roadblock",
        ),
      ],
      alternateRoutes: [
        AlternateRoute(
          name: "Route A",
          description: "Fastest",
          eta: "5 min",
        ),
        AlternateRoute(
          name: "Route B",
          description: "Less Congested",
          eta: "6 min",
        ),
      ],
    );
  }
}
