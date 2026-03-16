class DashboardModel {
  final String vehicleName;
  final String vehicleId;
  final String vehicleStatus;
  final String station;
  final String trafficDensity;
  final int nearbyIncidents;
  final List<RecentMission> recentMissions;

  DashboardModel({
    required this.vehicleName,
    required this.vehicleId,
    required this.vehicleStatus,
    required this.station,
    required this.trafficDensity,
    required this.nearbyIncidents,
    required this.recentMissions,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      vehicleName: json['vehicleName'] as String,
      vehicleId: json['vehicleId'] as String,
      vehicleStatus: json['vehicleStatus'] as String,
      station: json['station'] as String,
      trafficDensity: json['trafficDensity'] as String,
      nearbyIncidents: json['nearbyIncidents'] as int,
      recentMissions: (json['recentMissions'] as List)
          .map((e) => RecentMission.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RecentMission {
  final String from;
  final String to;
  final int durationMinutes;

  RecentMission({
    required this.from,
    required this.to,
    required this.durationMinutes,
  });

  factory RecentMission.fromJson(Map<String, dynamic> json) {
    return RecentMission(
      from: json['from'] as String,
      to: json['to'] as String,
      durationMinutes: json['durationMinutes'] as int,
    );
  }
}
