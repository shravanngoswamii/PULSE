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
    this.lat = 18.5204,
    this.lng = 73.8567,
  });

  factory TrafficAlert.fromJson(Map<String, dynamic> json) {
    return TrafficAlert(
      id: json['id'] as String,
      type: AlertType.values.firstWhere((e) => e.name == json['type']),
      severity: Severity.values.firstWhere((e) => e.name == json['severity']),
      title: json['title'] as String,
      location: json['location'] as String,
      intersectionId: json['intersectionId'] as String?,
      vehicleId: json['vehicleId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isActive: json['isActive'] as bool,
      description: json['description'] as String?,
      lat: (json['lat'] as num?)?.toDouble() ?? 18.5204,
      lng: (json['lng'] as num?)?.toDouble() ?? 73.8567,
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
