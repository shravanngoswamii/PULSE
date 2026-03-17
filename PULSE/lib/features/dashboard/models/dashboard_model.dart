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
  final String? startedAt;
  final String? completedAt;
  final String? status;

  RecentMission({
    required this.from,
    required this.to,
    required this.durationMinutes,
    this.startedAt,
    this.completedAt,
    this.status,
  });

  factory RecentMission.fromJson(Map<String, dynamic> json) {
    // Calculate duration from started_at and completed_at if duration not provided
    int duration = json['duration_minutes'] as int? ?? json['durationMinutes'] as int? ?? 0;
    if (duration == 0) {
      final startedAt = json['started_at'] as String?;
      final completedAt = json['completed_at'] as String?;
      if (startedAt != null && completedAt != null) {
        try {
          final start = DateTime.parse(startedAt);
          final end = DateTime.parse(completedAt);
          duration = end.difference(start).inMinutes;
        } catch (_) {}
      }
      if (duration == 0) {
        duration = (json['eta_minutes'] as num?)?.toInt() ?? 0;
      }
    }

    // Parse "to" field: prefer destination_name, then dest_name, then to
    final to = json['destination_name'] as String?
        ?? json['dest_name'] as String?
        ?? json['to'] as String?
        ?? 'Unknown';

    // Parse "from" field: prefer from, fallback to "Current Location"
    final from = json['from'] as String?
        ?? json['origin_name'] as String?
        ?? 'Current Location';

    return RecentMission(
      from: from,
      to: to,
      durationMinutes: duration,
      startedAt: json['started_at'] as String?,
      completedAt: json['completed_at'] as String?,
      status: json['status'] as String?,
    );
  }

  /// Returns a human-readable time-ago string from startedAt
  String get timeAgo {
    if (startedAt == null) return '';
    try {
      final start = DateTime.parse(startedAt!);
      final diff = DateTime.now().difference(start);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (_) {
      return '';
    }
  }
}
