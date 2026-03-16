class MissionSummaryModel {
  final String vehicleId;
  final String driverName;
  final String startTime;
  final String endTime;
  final double distanceTravelled;
  final int signalsPrioritized;
  final String pulseTime;
  final String normalTime;
  final int vehiclesAffected;
  final int signalsAdjusted;
  final String delaySaved;
  final List<List<double>> routeCoordinates;

  MissionSummaryModel({
    required this.vehicleId,
    required this.driverName,
    required this.startTime,
    required this.endTime,
    required this.distanceTravelled,
    required this.signalsPrioritized,
    required this.pulseTime,
    required this.normalTime,
    required this.vehiclesAffected,
    required this.signalsAdjusted,
    required this.delaySaved,
    required this.routeCoordinates,
  });

  factory MissionSummaryModel.mock() {
    return MissionSummaryModel(
      vehicleId: "PULSE-01",
      driverName: "John Doe",
      startTime: "10:32 AM",
      endTime: "10:41 AM",
      distanceTravelled: 4.2,
      signalsPrioritized: 5,
      pulseTime: "9 min",
      normalTime: "13 min",
      vehiclesAffected: 28,
      signalsAdjusted: 5,
      delaySaved: "2m 14s",
      routeCoordinates: [
        [40.7128, -74.0060],
        [40.7150, -74.0080],
        [40.7180, -74.0100],
        [40.7200, -74.0120],
      ],
    );
  }
}
