import 'package:pulse_ev/features/mission/models/hospital_model.dart';

enum MissionStatus { pending, active, completed, cancelled }

class MissionModel {
  final String missionId;
  final String incidentType;
  final String priorityLevel;
  final HospitalModel destinationHospital;
  final double distance;
  final String eta;
  final int signalsCleared;
  final MissionStatus status;
  final List<List<double>> routeCoordinates;
  final bool isRouteCalculating;
  final bool showHospitalNotification;

  MissionModel({
    required this.missionId,
    required this.incidentType,
    required this.priorityLevel,
    required this.destinationHospital,
    required this.distance,
    required this.eta,
    required this.signalsCleared,
    required this.status,
    this.routeCoordinates = const [],
    this.isRouteCalculating = false,
    this.showHospitalNotification = false,
  });

  MissionModel copyWith({
    String? missionId,
    String? incidentType,
    String? priorityLevel,
    HospitalModel? destinationHospital,
    double? distance,
    String? eta,
    int? signalsCleared,
    MissionStatus? status,
    List<List<double>>? routeCoordinates,
    bool? isRouteCalculating,
    bool? showHospitalNotification,
  }) {
    return MissionModel(
      missionId: missionId ?? this.missionId,
      incidentType: incidentType ?? this.incidentType,
      priorityLevel: priorityLevel ?? this.priorityLevel,
      destinationHospital: destinationHospital ?? this.destinationHospital,
      distance: distance ?? this.distance,
      eta: eta ?? this.eta,
      signalsCleared: signalsCleared ?? this.signalsCleared,
      status: status ?? this.status,
      routeCoordinates: routeCoordinates ?? this.routeCoordinates,
      isRouteCalculating: isRouteCalculating ?? this.isRouteCalculating,
      showHospitalNotification: showHospitalNotification ?? this.showHospitalNotification,
    );
  }
}
