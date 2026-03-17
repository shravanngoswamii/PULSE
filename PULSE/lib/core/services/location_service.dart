import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

// Default location fallback – AITR, Indore, India
// Used when the simulator has no location set or GPS is unavailable.
const double _kDefaultLat = 22.820567;
const double _kDefaultLng = 75.942712;

// Apple Park HQ coordinates – the iOS Simulator's default location.
// If we detect these coordinates we know the real GPS wasn't set.
const double _kAppleHQLat = 37.3349;
const double _kAppleHQLng = -122.0090;
const double _kAppleHQRadiusKm = 2.0; // generous radius around Apple Park

class LocationService {
  /// Requests permission (if needed) and returns the current device position.
  /// Falls back to Indore coordinates if GPS is unavailable / permission denied
  /// **or** if the simulator is returning Apple HQ coordinates.
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
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Guard: if the simulator reverted to the Apple HQ default, use fallback
      if (_isAppleHQ(position)) {
        return _indoreFallback();
      }
      return position;
    } catch (_) {
      // Try last known position before falling back to default
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && !_isAppleHQ(last)) {
        return last;
      }
      return _indoreFallback();
    }
  }

  /// Returns `true` when [pos] is within [_kAppleHQRadiusKm] of Apple Park.
  /// This signals the iOS Simulator has reverted to its factory-default location.
  static bool _isAppleHQ(Position pos) {
    return _haversineKm(
          pos.latitude,
          pos.longitude,
          _kAppleHQLat,
          _kAppleHQLng,
        ) <
        _kAppleHQRadiusKm;
  }

  /// Haversine distance in kilometres between two lat/lng points.
  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371.0; // Earth radius in km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180);

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
  /// Each emitted position is checked for the Apple HQ guard;
  /// simulator-default positions are replaced with the Indore fallback.
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // metres
      ),
    ).map((pos) => _isAppleHQ(pos) ? _indoreFallback() : pos);
  }
}
