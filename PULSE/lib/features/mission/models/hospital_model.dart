class HospitalModel {
  final String name;
  final double distance;
  final String eta;
  final List<double> coordinates;
  final int signalsToOverride;

  HospitalModel({
    required this.name,
    required this.distance,
    required this.eta,
    required this.coordinates,
    required this.signalsToOverride,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      name: json['name'] as String,
      distance: (json['distance'] as num).toDouble(),
      eta: json['eta'] as String,
      coordinates: (json['coordinates'] as List).map((e) => (e as num).toDouble()).toList(),
      signalsToOverride: json['signalsToOverride'] as int,
    );
  }
}
