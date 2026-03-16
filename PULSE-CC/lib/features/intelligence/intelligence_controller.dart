import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/intersection.dart';
import '../../data/repositories/intersection_repository.dart';

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

  IntelligenceController(this._intersectionRepository)
      : super(IntelligenceState(
          cityStats: const CityStats(
            vehiclesActive: 3482,
            avgSpeedKmh: 34.0,
            congestionZones: 7,
            trafficAlertsToday: 12,
          ),
          intersections: [],
          selectedDistrict: const DistrictData(
            sectorName: "Vijay Nagar",
            centerLat: 22.7196,
            centerLng: 75.8577,
            congestionPercent: 0.72,
          ),
          safetyAudit: const WeeklySafetyAudit(
            highRiskArea: "Downtown",
            accidentsThisWeek: 6,
            mostCommonCause: "Signal Violations",
          ),
          incidentInsights: const IncidentInsights(
            highRiskArea: "Downtown",
            accidentsThisWeek: 6,
            mostCommonCause: "Signal Violations",
          ),
        ));

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      final intersections = await _intersectionRepository.getIntersections();
      state = state.copyWith(intersections: intersections, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void selectDistrict(String sectorName) {
    if (sectorName == "Vijay Nagar") {
      state = state.copyWith(
        selectedDistrict: const DistrictData(
          sectorName: "Vijay Nagar",
          centerLat: 22.7196,
          centerLng: 75.8577,
          congestionPercent: 0.72,
        ),
      );
    }
  }

  void refreshStats() {
    state = state.copyWith(
      cityStats: CityStats(
        vehiclesActive: 3400 + (state.cityStats.vehiclesActive % 100) + 1,
        avgSpeedKmh: 34.0,
        congestionZones: 7,
        trafficAlertsToday: 12,
      ),
    );
  }
}

final intelligenceControllerProvider =
    StateNotifierProvider<IntelligenceController, IntelligenceState>((ref) {
  final repository = ref.watch(intersectionRepositoryProvider);
  return IntelligenceController(repository);
});
