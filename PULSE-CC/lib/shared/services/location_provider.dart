import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';

class LocationState {
  final Position? currentPosition;
  final bool hasPermission;

  const LocationState({
    this.currentPosition,
    this.hasPermission = false,
  });

  LocationState copyWith({
    Position? currentPosition,
    bool? hasPermission,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }
}

class LocationProvider extends StateNotifier<LocationState> {
  final LocationService _service;

  LocationProvider(this._service) : super(const LocationState()) {
    initialize();
  }

  Future<void> initialize() async {
    final hasPermission = await _service.requestPermission();
    if (hasPermission) {
      final position = await _service.getCurrentPosition();
      state = state.copyWith(
        hasPermission: true,
        currentPosition: position,
      );
    } else {
      state = state.copyWith(hasPermission: false);
    }
  }

  Future<void> refresh() async {
    if (state.hasPermission) {
      final position = await _service.getCurrentPosition();
      state = state.copyWith(currentPosition: position);
    } else {
      await initialize();
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationProvider = StateNotifierProvider<LocationProvider, LocationState>((ref) {
  final service = ref.watch(locationServiceProvider);
  return LocationProvider(service);
});
