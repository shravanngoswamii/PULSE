import 'package:equatable/equatable.dart';

enum VehicleType { ambulance, fire, police }
enum VehicleStatus { active, standby, completed }

class EmergencyVehicle extends Equatable {
  final String id;
  final VehicleType type;
  final String operator;
  final VehicleStatus status;
  final double currentLat;
  final double currentLng;
  final String destinationName;
  final String originName;
  final int etaSeconds;
  final double distanceKm;
  final String? corridorId;

  const EmergencyVehicle({
    required this.id,
    required this.type,
    required this.operator,
    required this.status,
    required this.currentLat,
    required this.currentLng,
    required this.destinationName,
    required this.originName,
    required this.etaSeconds,
    required this.distanceKm,
    this.corridorId,
  });

  EmergencyVehicle copyWith({
    String? id,
    VehicleType? type,
    String? operator,
    VehicleStatus? status,
    double? currentLat,
    double? currentLng,
    String? destinationName,
    String? originName,
    int? etaSeconds,
    double? distanceKm,
    String? corridorId,
  }) {
    return EmergencyVehicle(
      id: id ?? this.id,
      type: type ?? this.type,
      operator: operator ?? this.operator,
      status: status ?? this.status,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      destinationName: destinationName ?? this.destinationName,
      originName: originName ?? this.originName,
      etaSeconds: etaSeconds ?? this.etaSeconds,
      distanceKm: distanceKm ?? this.distanceKm,
      corridorId: corridorId ?? this.corridorId,
    );
  }

  factory EmergencyVehicle.fromJson(Map<String, dynamic> json) {
    return EmergencyVehicle(
      id: json['id'] as String,
      type: VehicleType.values.firstWhere((e) => e.name == json['type']),
      operator: json['operator'] as String,
      status: VehicleStatus.values.firstWhere((e) => e.name == json['status']),
      currentLat: (json['currentLat'] as num).toDouble(),
      currentLng: (json['currentLng'] as num).toDouble(),
      destinationName: json['destinationName'] as String,
      originName: json['originName'] as String,
      etaSeconds: json['etaSeconds'] as int,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      corridorId: json['corridorId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'operator': operator,
      'status': status.name,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'destinationName': destinationName,
      'originName': originName,
      'etaSeconds': etaSeconds,
      'distanceKm': distanceKm,
      'corridorId': corridorId,
    };
  }

  @override
  List<Object?> get props => [
        id, type, operator, status, currentLat, currentLng,
        destinationName, originName, etaSeconds, distanceKm, corridorId,
      ];
}
