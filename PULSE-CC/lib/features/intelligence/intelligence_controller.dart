import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/intersection.dart';
import '../../data/repositories/intersection_repository.dart';
import '../../data/repositories/mission_repository.dart';
import '../../data/repositories/alert_repository.dart';

class CityStats {
  final int vehiclesActive;
  final double avgSpeedKmh;
  final int congestionZones;
  final int trafficAlertsToday;

  const CityStats({
    required this.vehiclesActive,
    required this.avgSpeedKmh,
    required this.congestionZones,
    required this.trafficAlertsToday,
  });
}

class DistrictData {
  final String sectorName;
  final double centerLat;
  final double centerLng;
  final double congestionPercent;

  const DistrictData({
    required this.sectorName,
    required this.centerLat,
    required this.centerLng,
    required this.congestionPercent,
  });
}

class WeeklySafetyAudit {
  final String highRiskArea;
  final int accidentsThisWeek;
  final String mostCommonCause;

  const WeeklySafetyAudit({
    required this.highRiskArea,
    required this.accidentsThisWeek,
    required this.mostCommonCause,
  });
}

class IncidentInsights {
  final String highRiskArea;
  final int accidentsThisWeek;
  final String mostCommonCause;

  const IncidentInsights({
    required this.highRiskArea,
    required this.accidentsThisWeek,
    required this.mostCommonCause,
  });
}

class IntelligenceState {
  final CityStats cityStats;
  final List<Intersection> intersections;
  final DistrictData selectedDistrict;
  final WeeklySafetyAudit safetyAudit;
  final IncidentInsights incidentInsights;
  final bool isLoading;
  final String? errorMessage;

  IntelligenceState({
    required this.cityStats,
    required this.intersections,
    required this.selectedDistrict,
    required this.safetyAudit,
    required this.incidentInsights,
    this.isLoading = false,
    this.errorMessage,
  });

  IntelligenceState copyWith({
    CityStats? cityStats,
    List<Intersection>? intersections,
    DistrictData? selectedDistrict,
    WeeklySafetyAudit? safetyAudit,
    IncidentInsights? incidentInsights,
    bool? isLoading,
    String? errorMessage,
  }) {
    return IntelligenceState(
      cityStats: cityStats ?? this.cityStats,
      intersections: intersections ?? this.intersections,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      safetyAudit: safetyAudit ?? this.safetyAudit,
      incidentInsights: incidentInsights ?? this.incidentInsights,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class IntelligenceController extends StateNotifier<IntelligenceState> {
  final IntersectionRepository _intersectionRepository;
  final MissionRepository _missionRepository;
  final AlertRepository _alertRepository;

  IntelligenceController(
    this._intersectionRepository,
    this._missionRepository,
    this._alertRepository,
  ) : super(IntelligenceState(
          cityStats: const CityStats(
            vehiclesActive: 0,
            avgSpeedKmh: 0,
            congestionZones: 0,
            trafficAlertsToday: 0,
          ),
          intersections: [],
          selectedDistrict: const DistrictData(
            sectorName: "Vijay Nagar",
            centerLat: 22.7196,
            centerLng: 75.8577,
            congestionPercent: 0,
          ),
          safetyAudit: const WeeklySafetyAudit(
            highRiskArea: "N/A",
            accidentsThisWeek: 0,
            mostCommonCause: "N/A",
          ),
          incidentInsights: const IncidentInsights(
            highRiskArea: "N/A",
            accidentsThisWeek: 0,
            mostCommonCause: "N/A",
          ),
        ));

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      final intersections = await _intersectionRepository.getIntersections();
      final missions = await _missionRepository.getActiveMissions();
      final alerts = await _alertRepository.getAlerts();

      // Compute real stats from data
      final totalVehiclesWaiting = intersections.fold<int>(0, (sum, i) => sum + i.vehiclesWaiting);
      final congestionZones = intersections.where((i) => i.congestionLevel == CongestionLevel.high).length;
      final avgDelay = intersections.isNotEmpty
          ? intersections.fold<int>(0, (sum, i) => sum + i.avgDelaySeconds) / intersections.length
          : 0.0;
      // Estimate avg speed: lower delay = higher speed (rough heuristic)
      final avgSpeed = avgDelay > 0 ? (50.0 - avgDelay * 0.5).clamp(10.0, 60.0) : 35.0;

      // Find highest congestion district
      final districtCongestion = <String, List<Intersection>>{};
      for (final i in intersections) {
        districtCongestion.putIfAbsent(i.district, () => []).add(i);
      }
      String peakDistrict = "Vijay Nagar";
      double peakCongestion = 0;
      double peakLat = 22.7196, peakLng = 75.8577;
      for (final entry in districtCongestion.entries) {
        final highCount = entry.value.where((i) => i.congestionLevel == CongestionLevel.high).length;
        final double pct = entry.value.isNotEmpty ? highCount / entry.value.length : 0.0;
        if (pct > peakCongestion) {
          peakCongestion = pct;
          peakDistrict = entry.key;
          peakLat = entry.value.first.lat;
          peakLng = entry.value.first.lng;
        }
      }

      state = state.copyWith(
        intersections: intersections,
        cityStats: CityStats(
          vehiclesActive: totalVehiclesWaiting + missions.length,
          avgSpeedKmh: avgSpeed,
          congestionZones: congestionZones,
          trafficAlertsToday: alerts.length,
        ),
        selectedDistrict: DistrictData(
          sectorName: peakDistrict,
          centerLat: peakLat,
          centerLng: peakLng,
          congestionPercent: peakCongestion,
        ),
        safetyAudit: WeeklySafetyAudit(
          highRiskArea: peakDistrict,
          accidentsThisWeek: alerts.length,
          mostCommonCause: alerts.isNotEmpty ? alerts.first.type.name : "N/A",
        ),
        incidentInsights: IncidentInsights(
          highRiskArea: peakDistrict,
          accidentsThisWeek: alerts.length,
          mostCommonCause: alerts.isNotEmpty ? alerts.first.type.name : "N/A",
        ),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void selectDistrict(String sectorName) {
    final intersections = state.intersections;
    final districtIntersections = intersections.where((i) => i.district == sectorName).toList();
    if (districtIntersections.isNotEmpty) {
      final highCount = districtIntersections.where((i) => i.congestionLevel == CongestionLevel.high).length;
      state = state.copyWith(
        selectedDistrict: DistrictData(
          sectorName: sectorName,
          centerLat: districtIntersections.first.lat,
          centerLng: districtIntersections.first.lng,
          congestionPercent: highCount / districtIntersections.length,
        ),
      );
    }
  }

  Future<void> refreshStats() async {
    await initialize();
  }
}

final intelligenceControllerProvider =
    StateNotifierProvider<IntelligenceController, IntelligenceState>((ref) {
  final intersectionRepo = ref.watch(intersectionRepositoryProvider);
  final missionRepo = ref.watch(missionRepositoryProvider);
  final alertRepo = ref.watch(alertRepositoryProvider);
  return IntelligenceController(intersectionRepo, missionRepo, alertRepo);
});
