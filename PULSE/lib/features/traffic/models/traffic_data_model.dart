class TrafficDataModel {
  final String trafficDensity;
  final int blockedRoads;
  final int avgSignalTime;
  final List<TrafficIncident> incidents;
  final List<AlternateRoute> alternateRoutes;

  TrafficDataModel({
    required this.trafficDensity,
    required this.blockedRoads,
    required this.avgSignalTime,
    required this.incidents,
    required this.alternateRoutes,
  });
}

class TrafficIncident {
  final String title;
  final String location;
  final String distance;
  final String type;

  TrafficIncident({
    required this.title,
    required this.location,
    required this.distance,
    required this.type,
  });
}

class AlternateRoute {
  final String name;
  final String description;
  final String eta;

  AlternateRoute({
    required this.name,
    required this.description,
    required this.eta,
  });
}
