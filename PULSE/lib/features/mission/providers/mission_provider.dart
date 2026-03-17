import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_ev/core/network/api_client.dart';
import 'package:pulse_ev/core/services/location_service.dart';
import 'package:pulse_ev/core/storage/token_storage.dart';
import 'package:pulse_ev/features/auth/providers/user_provider.dart';
import 'package:pulse_ev/features/dashboard/providers/dashboard_provider.dart';
import 'package:pulse_ev/features/mission/models/hospital_model.dart';
import 'package:pulse_ev/features/mission/models/mission_model.dart';
import 'package:pulse_ev/features/mission/repositories/mission_repository.dart';
import 'package:pulse_ev/features/mission/services/mission_api_service.dart';

// Providers
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage: tokenStorage);
});

final missionApiServiceProvider = Provider<MissionApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MissionApiService(apiClient);
});

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  final apiService = ref.watch(missionApiServiceProvider);
  return MissionRepository(apiService);
});

final hospitalsProvider = FutureProvider.family<List<HospitalModel>, ({double lat, double lng})>(
  (ref, coords) async {
    final repository = ref.watch(missionRepositoryProvider);
    return await repository.getHospitals(coords.lat, coords.lng);
  },
);

// Mission State Notifier
class MissionNotifier extends StateNotifier<MissionModel?> {
  final MissionRepository _repository;
  final Ref _ref;
  StreamSubscription? _gpsSubscription;
  Timer? _pingTimer;

  MissionNotifier(this._repository, this._ref) : super(null);

  void restoreFromBackend(Map<String, dynamic> missionData) {
    if (state != null && state!.status == MissionStatus.active) return;

    final missionId = (missionData['id'] ?? '').toString();
    final status = missionData['status'] as String?;
    if (status != 'active' || missionId.isEmpty) return;

    final destName = missionData['destination_name'] as String? ?? '';
    final destLat = (missionData['destination_lat'] as num?)?.toDouble() ?? 0.0;
    final destLng = (missionData['destination_lng'] as num?)?.toDouble() ?? 0.0;
    final distanceKm = (missionData['distance_km'] as num?)?.toDouble() ?? 0.0;
    final etaMin = (missionData['eta_minutes'] as num?)?.toDouble() ?? 0.0;
    final signalsCleared = (missionData['signals_cleared'] as num?)?.toInt() ?? 0;

    state = MissionModel(
      missionId: missionId,
      incidentType: missionData['incident_type'] as String? ?? '',
      priorityLevel: missionData['priority'] as String? ?? '',
      destinationHospital: HospitalModel(
        id: 'restored',
        name: destName,
        lat: destLat,
        lng: destLng,
        distanceKm: distanceKm,
        etaMinutes: etaMin,
      ),
      distance: distanceKm,
      eta: '${etaMin.toInt()} min',
      signalsCleared: signalsCleared,
      status: MissionStatus.active,
    );

    _startGpsTracking(missionId);
  }

  Future<void> startMission({
    required String incidentType,
    required String priority,
    required HospitalModel hospital,
    required double originLat,
    required double originLng,
  }) async {
    final user = _ref.read(currentUserProvider);
    final vehicleId = user?.vehicleId ?? '';

    // Phase 1: Set state IMMEDIATELY so the UI can navigate to the map screen
    state = MissionModel(
      missionId: 'pending',
      incidentType: incidentType,
      priorityLevel: priority,
      destinationHospital: hospital,
      distance: hospital.distanceKm,
      eta: '${hospital.etaMinutes.toInt()} min',
      signalsCleared: 0,
      status: MissionStatus.active,
      isRouteCalculating: true,
      showHospitalNotification: true,
    );

    // Auto-dismiss hospital notification after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (state != null && state!.showHospitalNotification) {
        state = state!.copyWith(showHospitalNotification: false);
      }
    });

    // Phase 2: Fire the API call in the background
    try {
      final response = await _repository.startMission(
        vehicleId: vehicleId,
        destLat: hospital.lat,
        destLng: hospital.lng,
        destName: hospital.name,
        incidentType: incidentType,
        priority: priority,
        originLat: originLat,
        originLng: originLng,
      );

      final missionId = (response['mission_id'] ?? response['id'] ?? '').toString();
      final routeCoords = <List<double>>[];
      final rawCoords = response['route_coordinates'] as List?;
      if (rawCoords != null) {
        for (final coord in rawCoords) {
          if (coord is Map) {
            final lat = (coord['lat'] as num?)?.toDouble();
            final lng = (coord['lng'] as num?)?.toDouble();
            if (lat != null && lng != null) {
              routeCoords.add([lat, lng]);
            }
          } else if (coord is List) {
            routeCoords.add(coord.map((e) => (e as num).toDouble()).toList());
          }
        }
      }

      final distanceKm = (response['distance_km'] as num?)?.toDouble() ?? hospital.distanceKm;
      final etaMin = (response['eta_minutes'] as num?)?.toDouble() ?? hospital.etaMinutes;

      // Only use route if it has enough points to be a real road-following path
      // (2 points = straight line fallback from OSRM failure)
      final validRoute = routeCoords.length > 2 ? routeCoords : <List<double>>[];

      // Update state with real route data
      state = state?.copyWith(
        missionId: missionId,
        distance: distanceKm,
        eta: '${etaMin.toInt()} min',
        routeCoordinates: validRoute,
        isRouteCalculating: false,
      );

      _startGpsTracking(missionId);
    } catch (e) {
      // Even if API fails, keep the mission active with estimated data
      state = state?.copyWith(isRouteCalculating: false);
    }
  }

  void _startGpsTracking(String missionId) {
    _stopGpsTracking();

    // Ping GPS every 5 seconds
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (state == null || state!.status != MissionStatus.active) {
        _stopGpsTracking();
        return;
      }
      try {
        final position = await LocationService.getCurrentPosition();
        if (position != null) {
          final response = await _repository.pingGPS(missionId, position.latitude, position.longitude);
          // Update mission state from ping response
          if (state != null && response.isNotEmpty) {
            final updatedEta = (response['eta_minutes'] as num?)?.toDouble();
            final updatedDistance = (response['distance_km'] as num?)?.toDouble();
            final updatedSignals = response['signals_cleared'] as int?;
            final rawCoords = response['route_coordinates'] as List?;
            List<List<double>>? updatedRoute;
            if (rawCoords != null && rawCoords.length > 2) {
              updatedRoute = <List<double>>[];
              for (final coord in rawCoords) {
                if (coord is Map) {
                  final lat = (coord['lat'] as num?)?.toDouble();
                  final lng = (coord['lng'] as num?)?.toDouble();
                  if (lat != null && lng != null) {
                    updatedRoute.add([lat, lng]);
                  }
                } else if (coord is List) {
                  updatedRoute.add(coord.map((e) => (e as num).toDouble()).toList());
                }
              }
              // Only use if we got a meaningful number of points
              if (updatedRoute.length <= 2) updatedRoute = null;
            }
            state = state!.copyWith(
              eta: updatedEta != null ? '${updatedEta.toInt()} min' : null,
              distance: updatedDistance,
              signalsCleared: updatedSignals,
              routeCoordinates: updatedRoute,
            );
          }
        }
      } catch (_) {
        // Silently handle ping failures
      }
    });
  }

  void _stopGpsTracking() {
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  Future<void> endMission() async {
    if (state != null) {
      _stopGpsTracking();
      // Only call backend if we have a real mission ID (not 'pending')
      if (state!.missionId != 'pending') {
        try {
          await _repository.endMission(state!.missionId);
        } catch (_) {
          // Continue even if backend fails — stop mission locally
        }
      }
      state = state!.copyWith(status: MissionStatus.completed);
      // Invalidate dashboard so it refetches with the newly completed mission
      _ref.invalidate(dashboardProvider);
    }
  }

  @override
  void dispose() {
    _stopGpsTracking();
    super.dispose();
  }
}

final missionProvider = StateNotifierProvider<MissionNotifier, MissionModel?>((ref) {
  final repository = ref.watch(missionRepositoryProvider);
  return MissionNotifier(repository, ref);
});
