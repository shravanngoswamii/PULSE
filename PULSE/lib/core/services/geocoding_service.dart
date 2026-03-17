import 'package:dio/dio.dart';

class GeocodingService {
  static final _dio = Dio(
    BaseOptions(
      baseUrl: 'https://nominatim.openstreetmap.org',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'User-Agent': 'PulseEV/1.0 (flutter)',
        'Accept-Language': 'en',
      },
    ),
  );

  /// Reverse geocodes a latitude/longitude pair into a human-readable place name.
  /// Uses the Nominatim OpenStreetMap API (free, no key required).
  /// Returns null if the request fails or no result is found.
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reverse',
        queryParameters: {
          'format': 'json',
          'lat': lat,
          'lon': lng,
          'zoom': 16,
          'addressdetails': 1,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          // Build a short readable label: road + suburb / city
          final parts = <String>[];
          final road = address['road'] as String?;
          final suburb = address['suburb'] as String?;
          final city = address['city'] as String? ??
              address['town'] as String? ??
              address['village'] as String?;

          if (road != null) parts.add(road);
          if (suburb != null) parts.add(suburb);
          if (city != null) parts.add(city);

          if (parts.isNotEmpty) return parts.join(', ');
        }

        // Fall back to display_name
        return data['display_name'] as String?;
      }
    } catch (_) {
      // Return null on any network error
    }
    return null;
  }
}
