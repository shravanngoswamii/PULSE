class HospitalModel {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String? address;
  final String? phone;
  final double distanceKm;
  final double etaMinutes;

  HospitalModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
    this.phone,
    required this.distanceKm,
    required this.etaMinutes,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      etaMinutes: (json['eta_minutes'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Formatted ETA string for display
  String get eta => '${etaMinutes.toInt()} min';

  /// Alias for backward compatibility
  double get distance => distanceKm;
}
