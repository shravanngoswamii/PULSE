import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_ev/features/dashboard/providers/dashboard_provider.dart';
import 'package:pulse_ev/core/network/api_client.dart';
import 'package:pulse_ev/core/services/location_service.dart';
import 'package:pulse_ev/core/storage/token_storage.dart';
import 'package:pulse_ev/features/auth/providers/user_provider.dart';
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
  Completer<void>? _startCompleter;

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
    bool autoDrive = false,
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
      isAutoDrive: autoDrive,
      currentLat: originLat,
      currentLng: originLng,
    );

    // Auto-dismiss hospital notification after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (state != null && state!.showHospitalNotification) {
        state = state!.copyWith(showHospitalNotification: false);
      }
    });

    // Phase 2: Fire the API call in the background, tracked by completer
    _startCompleter = Completer<void>();
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
        autoDrive: autoDrive,
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
    } finally {
      _startCompleter?.complete();
      _startCompleter = null;
    }
  }

  void _startGpsTracking(String missionId) {
    _stopGpsTracking();

    // Ping more frequently for auto-drive (2s) vs manual driving (5s)
    final interval = (state?.isAutoDrive == true) ? 2 : 5;
    _pingTimer = Timer.periodic(Duration(seconds: interval), (_) async {
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
            // Update vehicle position from backend (for auto-drive)
            final simLat = (response['current_lat'] as num?)?.toDouble();
            final simLng = (response['current_lng'] as num?)?.toDouble();

            // Check if backend has auto-completed the mission,
            // OR if distance/ETA are effectively zero (vehicle arrived)
            final missionStatus = response['status'] as String?;
            final arrivedByDistance = (updatedDistance != null && updatedDistance < 0.05)
                && (updatedEta != null && updatedEta < 0.3);
            if (missionStatus == 'completed' || arrivedByDistance) {
              _stopGpsTracking();
              state = state!.copyWith(
                status: MissionStatus.completed,
                distance: 0,
                eta: 'Arrived',
                signalsCleared: updatedSignals,
                currentLat: simLat,
                currentLng: simLng,
              );
              _ref.invalidate(dashboardProvider);
              return;
            }

            // Format ETA/distance with enough precision for small values
            String? etaText;
            if (updatedEta != null) {
              if (updatedEta < 1) {
                etaText = '${(updatedEta * 60).toInt()} sec';
              } else {
                etaText = '${updatedEta.toStringAsFixed(1)} min';
              }
            }

            state = state!.copyWith(
              eta: etaText,
              distance: updatedDistance,
              signalsCleared: updatedSignals,
              routeCoordinates: updatedRoute,
              currentLat: simLat,
              currentLng: simLng,
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
    if (state == null) return;

    // If the start API is still running, wait for it to finish
    // so we have the real missionId
    if (_startCompleter != null && !_startCompleter!.isCompleted) {
      await _startCompleter!.future;
    }

    final missionId = state!.missionId;
    _stopGpsTracking();

    // Only call backend if we have a real mission ID
    if (missionId.isNotEmpty && missionId != 'pending') {
      try {
        await _repository.endMission(missionId);
      } catch (_) {
        // Continue even if backend fails
      }
    }

    state = state!.copyWith(status: MissionStatus.completed);

    // Invalidate dashboard so it re-fetches with the new completed mission
    _ref.invalidate(dashboardProvider);
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
