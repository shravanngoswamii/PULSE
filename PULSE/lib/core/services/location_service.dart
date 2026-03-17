import 'package:geolocator/geolocator.dart';

// Default location fallback – AITR, Indore, India
// Used when the simulator has no location set or GPS is unavailable.
const double _kDefaultLat = 22.820567;
const double _kDefaultLng = 75.942712;

class LocationService {
  /// Requests permission (if needed) and returns the current device position.
  /// Falls back to Indore coordinates if GPS is unavailable / permission denied.
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return _indoreFallback();
    }

    // Check / request permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return _indoreFallback();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return _indoreFallback();
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      // Try last known position before falling back to default
      final last = await Geolocator.getLastKnownPosition();
      return last ?? _indoreFallback();
    }
  }

  /// Returns a synthetic Position centred on Indore, India.
  /// Used as a sensible default when GPS is unavailable (e.g. simulator with no location set).
  static Position _indoreFallback() {
    return Position(
      latitude: _kDefaultLat,
      longitude: _kDefaultLng,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  /// Returns a continuous stream of device position updates.
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // metres
      ),
    );
  }
}
