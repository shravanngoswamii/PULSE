class SettingsModel {
  // Notifications Section
  final bool missionAlerts;
  final bool trafficAlerts;
  final bool signalPriorityAlerts;
  final bool incidentNotifications;

  // Navigation Settings Section
  final bool voiceGuidance;
  final bool routeRecalculation;
  final bool avoidHeavyTraffic;
  final String mapOrientation;

  // System Settings Section
  final String dataSyncMode;
  final bool mapDataRefresh;
  final bool simulationMode;

  // Emergency Preferences Section
  final bool autoSignalOverride;
  final bool emergencySirenSync;
  final bool trafficAuthorityLink;

  SettingsModel({
    required this.missionAlerts,
    required this.trafficAlerts,
    required this.signalPriorityAlerts,
    required this.incidentNotifications,
    required this.voiceGuidance,
    required this.routeRecalculation,
    required this.avoidHeavyTraffic,
    required this.mapOrientation,
    required this.dataSyncMode,
    required this.mapDataRefresh,
    required this.simulationMode,
    required this.autoSignalOverride,
    required this.emergencySirenSync,
    required this.trafficAuthorityLink,
  });

  factory SettingsModel.defaultSettings() {
    return SettingsModel(
      missionAlerts: true,
      trafficAlerts: true,
      signalPriorityAlerts: true,
      incidentNotifications: false,
      voiceGuidance: true,
      routeRecalculation: true,
      avoidHeavyTraffic: true,
      mapOrientation: "Auto",
      dataSyncMode: "Auto",
      mapDataRefresh: true,
      simulationMode: false,
      autoSignalOverride: true,
      emergencySirenSync: true,
      trafficAuthorityLink: true,
    );
  }

  SettingsModel copyWith({
    bool? missionAlerts,
    bool? trafficAlerts,
    bool? signalPriorityAlerts,
    bool? incidentNotifications,
    bool? voiceGuidance,
    bool? routeRecalculation,
    bool? avoidHeavyTraffic,
    String? mapOrientation,
    String? dataSyncMode,
    bool? mapDataRefresh,
    bool? simulationMode,
    bool? autoSignalOverride,
    bool? emergencySirenSync,
    bool? trafficAuthorityLink,
  }) {
    return SettingsModel(
      missionAlerts: missionAlerts ?? this.missionAlerts,
      trafficAlerts: trafficAlerts ?? this.trafficAlerts,
      signalPriorityAlerts: signalPriorityAlerts ?? this.signalPriorityAlerts,
      incidentNotifications: incidentNotifications ?? this.incidentNotifications,
      voiceGuidance: voiceGuidance ?? this.voiceGuidance,
      routeRecalculation: routeRecalculation ?? this.routeRecalculation,
      avoidHeavyTraffic: avoidHeavyTraffic ?? this.avoidHeavyTraffic,
      mapOrientation: mapOrientation ?? this.mapOrientation,
      dataSyncMode: dataSyncMode ?? this.dataSyncMode,
      mapDataRefresh: mapDataRefresh ?? this.mapDataRefresh,
      simulationMode: simulationMode ?? this.simulationMode,
      autoSignalOverride: autoSignalOverride ?? this.autoSignalOverride,
      emergencySirenSync: emergencySirenSync ?? this.emergencySirenSync,
      trafficAuthorityLink: trafficAuthorityLink ?? this.trafficAuthorityLink,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'missionAlerts': missionAlerts,
      'trafficAlerts': trafficAlerts,
      'signalPriorityAlerts': signalPriorityAlerts,
      'incidentNotifications': incidentNotifications,
      'voiceGuidance': voiceGuidance,
      'routeRecalculation': routeRecalculation,
      'avoidHeavyTraffic': avoidHeavyTraffic,
      'mapOrientation': mapOrientation,
      'dataSyncMode': dataSyncMode,
      'mapDataRefresh': mapDataRefresh,
      'simulationMode': simulationMode,
      'autoSignalOverride': autoSignalOverride,
      'emergencySirenSync': emergencySirenSync,
      'trafficAuthorityLink': trafficAuthorityLink,
    };
  }

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      missionAlerts: json['missionAlerts'] ?? true,
      trafficAlerts: json['trafficAlerts'] ?? true,
      signalPriorityAlerts: json['signalPriorityAlerts'] ?? true,
      incidentNotifications: json['incidentNotifications'] ?? false,
      voiceGuidance: json['voiceGuidance'] ?? true,
      routeRecalculation: json['routeRecalculation'] ?? true,
      avoidHeavyTraffic: json['avoidHeavyTraffic'] ?? true,
      mapOrientation: json['mapOrientation'] ?? "Auto",
      dataSyncMode: json['dataSyncMode'] ?? "Auto",
      mapDataRefresh: json['mapDataRefresh'] ?? true,
      simulationMode: json['simulationMode'] ?? false,
      autoSignalOverride: json['autoSignalOverride'] ?? true,
      emergencySirenSync: json['emergencySirenSync'] ?? true,
      trafficAuthorityLink: json['trafficAuthorityLink'] ?? true,
    );
  }
}
