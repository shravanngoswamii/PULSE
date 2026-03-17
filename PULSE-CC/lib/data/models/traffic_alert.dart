import 'package:equatable/equatable.dart';

enum AlertType { accident, signalFailure, emergencyVehicle, congestion }
enum Severity { high, medium, low }

class TrafficAlert extends Equatable {
  final String id;
  final AlertType type;
  final Severity severity;
  final String title;
  final String location;
  final String? intersectionId;
  final String? vehicleId;
  final DateTime timestamp;
  final bool isActive;
  final String? description;
  final double lat;
  final double lng;

  const TrafficAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.location,
    this.intersectionId,
    this.vehicleId,
    required this.timestamp,
    required this.isActive,
    this.description,
    this.lat = 22.7196,
    this.lng = 75.8577,
  });

  factory TrafficAlert.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] ?? 'accident') as String;
    // Map backend type names (e.g. 'emergency_vehicle', 'signal_failure') to enum names
    final typeMap = {
      'accident': AlertType.accident,
      'signal_failure': AlertType.signalFailure,
      'signalFailure': AlertType.signalFailure,
      'emergency_vehicle': AlertType.emergencyVehicle,
      'emergencyVehicle': AlertType.emergencyVehicle,
      'congestion': AlertType.congestion,
    };
    final sevStr = (json['severity'] ?? 'medium') as String;
    final timestampStr = json['timestamp'] as String?
        ?? json['created_at'] as String?
        ?? DateTime.now().toIso8601String();

    return TrafficAlert(
      id: json['id'] as String,
      type: typeMap[typeStr] ?? AlertType.accident,
      severity: Severity.values.firstWhere((e) => e.name == sevStr, orElse: () => Severity.medium),
      title: json['title'] as String? ?? '',
      location: json['location'] as String? ?? '',
      intersectionId: (json['intersectionId'] ?? json['intersection_id']) as String?,
      vehicleId: (json['vehicleId'] ?? json['vehicle_id']) as String?,
      timestamp: DateTime.tryParse(timestampStr) ?? DateTime.now(),
      isActive: (json['isActive'] ?? json['is_active'] ?? true) as bool,
      description: json['description'] as String?,
      lat: (json['lat'] as num?)?.toDouble() ?? 22.7196,
      lng: (json['lng'] as num?)?.toDouble() ?? 75.8577,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'severity': severity.name,
      'title': title,
      'location': location,
      'intersectionId': intersectionId,
      'vehicleId': vehicleId,
      'timestamp': timestamp.toIso8601String(),
      'isActive': isActive,
      'description': description,
      'lat': lat,
      'lng': lng,
    };
  }

  @override
  List<Object?> get props => [
        id, type, severity, title, location, intersectionId,
        vehicleId, timestamp, isActive, description, lat, lng,
      ];
}
