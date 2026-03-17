class DashboardModel {
  final String vehicleName;
  final String vehicleId;
  final String vehicleStatus;
  final String station;
  final String trafficDensity;
  final int nearbyIncidents;
  final List<RecentMission> recentMissions;
  final Map<String, dynamic>? activeMission;

  DashboardModel({
    required this.vehicleName,
    required this.vehicleId,
    required this.vehicleStatus,
    required this.station,
    required this.trafficDensity,
    required this.nearbyIncidents,
    required this.recentMissions,
    this.activeMission,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicle'] as Map<String, dynamic>?;

    return DashboardModel(
      vehicleName: vehicle?['name'] as String? ?? json['vehicle_name'] as String? ?? '',
      vehicleId: vehicle?['id'] as String? ?? json['vehicle_id'] as String? ?? '',
      vehicleStatus: vehicle?['status'] as String? ?? json['vehicle_status'] as String? ?? 'standby',
      station: json['station'] as String? ?? '',
      trafficDensity: json['traffic_density'] as String? ?? 'Unknown',
      nearbyIncidents: json['nearby_incidents'] as int? ?? 0,
      activeMission: json['active_mission'] as Map<String, dynamic>?,
      recentMissions: ((json['recent_missions'] ?? json['recentMissions']) as List?)
              ?.map((e) => RecentMission.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class RecentMission {
  final String id;
  final String from;
  final String to;
  final int durationMinutes;
  final String? startedAt;
  final String? completedAt;
  final String? status;
  final String? incidentType;
  final String? priority;
  final double? destinationLat;
  final double? destinationLng;
  final double? distanceKm;
  final double? etaMinutes;
  final int signalsCleared;
  final String? vehicleName;

  RecentMission({
    required this.id,
    required this.from,
    required this.to,
    required this.durationMinutes,
    this.startedAt,
    this.completedAt,
    this.status,
    this.incidentType,
    this.priority,
    this.destinationLat,
    this.destinationLng,
    this.distanceKm,
    this.etaMinutes,
    this.signalsCleared = 0,
    this.vehicleName,
  });

  factory RecentMission.fromJson(Map<String, dynamic> json) {
    // Calculate duration from started_at and completed_at if duration not provided
    int duration = json['duration_minutes'] as int? ?? json['durationMinutes'] as int? ?? 0;
    if (duration == 0) {
      final startedStr = json['started_at']?.toString();
      final completedStr = json['completed_at']?.toString();
      if (startedStr != null && completedStr != null) {
        try {
          final start = DateTime.parse(startedStr);
          final end = DateTime.parse(completedStr);
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
      id: (json['id'] ?? '').toString(),
      from: from,
      to: to,
      durationMinutes: duration,
      startedAt: json['started_at']?.toString(),
      completedAt: json['completed_at']?.toString(),
      status: json['status'] as String?,
      incidentType: json['incident_type'] as String?,
      priority: json['priority'] as String?,
      destinationLat: (json['destination_lat'] as num?)?.toDouble(),
      destinationLng: (json['destination_lng'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      etaMinutes: (json['eta_minutes'] as num?)?.toDouble(),
      signalsCleared: (json['signals_cleared'] as num?)?.toInt() ?? 0,
      vehicleName: json['vehicle_name'] as String?,
    );
  }

  /// Returns a human-readable time-ago string from startedAt
  String get timeAgo {
    if (startedAt == null) return '';
    try {
      // Backend sends UTC timestamps — ensure we parse as UTC and compare with UTC now
      var start = DateTime.parse(startedAt!);
      if (!start.isUtc) {
        start = DateTime.utc(start.year, start.month, start.day, start.hour, start.minute, start.second);
      }
      final diff = DateTime.now().toUtc().difference(start);
      if (diff.isNegative) return 'just now';
      if (diff.inSeconds < 60) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (_) {
      return '';
    }
  }
}
