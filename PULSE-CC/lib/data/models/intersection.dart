import 'package:equatable/equatable.dart';

enum SignalMode { automatic, manual, emergency }
enum SignalPhase { green, red, amber, preCleared }
enum CongestionLevel { low, moderate, high }

class Intersection extends Equatable {
  final String id;
  final String name;
  final String district;
  final double lat;
  final double lng;
  final SignalMode signalMode;
  final SignalPhase currentPhase;
  final int vehiclesWaiting;
  final int avgDelaySeconds;
  final CongestionLevel congestionLevel;
  final DateTime? lastOverride;
  final String? assignedVehicleId;

  const Intersection({
    required this.id,
    required this.name,
    required this.district,
    required this.lat,
    required this.lng,
    required this.signalMode,
    required this.currentPhase,
    required this.vehiclesWaiting,
    required this.avgDelaySeconds,
    required this.congestionLevel,
    this.lastOverride,
    this.assignedVehicleId,
  });

  Intersection copyWith({
    String? id,
    String? name,
    String? district,
    double? lat,
    double? lng,
    SignalMode? signalMode,
    SignalPhase? currentPhase,
    int? vehiclesWaiting,
    int? avgDelaySeconds,
    CongestionLevel? congestionLevel,
    DateTime? lastOverride,
    String? assignedVehicleId,
  }) {
    return Intersection(
      id: id ?? this.id,
      name: name ?? this.name,
      district: district ?? this.district,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      signalMode: signalMode ?? this.signalMode,
      currentPhase: currentPhase ?? this.currentPhase,
      vehiclesWaiting: vehiclesWaiting ?? this.vehiclesWaiting,
      avgDelaySeconds: avgDelaySeconds ?? this.avgDelaySeconds,
      congestionLevel: congestionLevel ?? this.congestionLevel,
      lastOverride: lastOverride ?? this.lastOverride,
      assignedVehicleId: assignedVehicleId ?? this.assignedVehicleId,
    );
  }

  factory Intersection.fromJson(Map<String, dynamic> json) {
    final modeStr = (json['signalMode'] ?? json['signal_mode'] ?? 'automatic') as String;
    final phaseStr = (json['currentPhase'] ?? json['current_phase'] ?? 'green') as String;
    final congestionStr = (json['congestionLevel'] ?? json['congestion_level'] ?? 'low') as String;

    return Intersection(
      id: json['id'] as String,
      name: json['name'] as String,
      district: json['district'] as String? ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      signalMode: SignalMode.values.firstWhere((e) => e.name == modeStr, orElse: () => SignalMode.automatic),
      currentPhase: SignalPhase.values.firstWhere((e) => e.name == phaseStr, orElse: () => SignalPhase.green),
      vehiclesWaiting: (json['vehiclesWaiting'] ?? json['vehicles_waiting'] ?? 0) as int,
      avgDelaySeconds: (json['avgDelaySeconds'] ?? json['avg_delay_seconds'] ?? 0) as int,
      congestionLevel: CongestionLevel.values.firstWhere((e) => e.name == congestionStr, orElse: () => CongestionLevel.low),
      lastOverride: json['lastOverride'] != null ? DateTime.parse(json['lastOverride'] as String) : null,
      assignedVehicleId: (json['assignedVehicleId'] ?? json['assigned_vehicle_id'] ?? json['assigned_operator_id']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'district': district,
      'lat': lat,
      'lng': lng,
      'signalMode': signalMode.name,
      'currentPhase': currentPhase.name,
      'vehiclesWaiting': vehiclesWaiting,
      'avgDelaySeconds': avgDelaySeconds,
      'congestionLevel': congestionLevel.name,
      'lastOverride': lastOverride?.toIso8601String(),
      'assignedVehicleId': assignedVehicleId,
    };
  }

  @override
  List<Object?> get props => [
        id, name, district, lat, lng, signalMode, currentPhase,
        vehiclesWaiting, avgDelaySeconds, congestionLevel, lastOverride, assignedVehicleId,
      ];
}
