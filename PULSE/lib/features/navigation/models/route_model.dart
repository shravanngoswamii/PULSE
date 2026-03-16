class RouteModel {
  final double distance;
  final String eta;
  final int signalsCleared;
  final String nextIntersection;
  final String corridorStatus;

  RouteModel({
    required this.distance,
    required this.eta,
    required this.signalsCleared,
    required this.nextIntersection,
    required this.corridorStatus,
  });
}
