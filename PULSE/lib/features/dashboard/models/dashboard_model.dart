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
      vehicleName: json['vehicle_name'] as String? ?? json['vehicleName'] as String? ?? '',
      vehicleId: json['vehicle_id'] as String? ?? json['vehicleId'] as String? ?? '',
      vehicleStatus: json['vehicle_status'] as String? ?? json['vehicleStatus'] as String? ?? 'AVAILABLE',
      station: json['station'] as String? ?? '',
      trafficDensity: json['traffic_density'] as String? ?? json['trafficDensity'] as String? ?? 'Unknown',
      nearbyIncidents: json['nearby_incidents'] as int? ?? json['nearbyIncidents'] as int? ?? 0,
      recentMissions: ((json['recent_missions'] ?? json['recentMissions']) as List?)
              ?.map((e) => RecentMission.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      durationMinutes: json['duration_minutes'] as int? ?? json['durationMinutes'] as int? ?? 0,
    );
  }
}
