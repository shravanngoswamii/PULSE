import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String formatEta(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) return '${minutes}m';
    return '${minutes}m ${remainingSeconds}s';
  }

  static String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  static String formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  static String formatTimestamp(DateTime dt) {
    return DateFormat('h:mm a · MMM d').format(dt);
  }

  static String formatVehicleId(String id) {
    if (id.isEmpty) return id;
    if (id.contains('-')) return id;
    // Basic formatting example if length >= 3
    if (id.length >= 3) {
      return '${id.substring(0, 3).toUpperCase()}-${id.substring(3)}';
    }
    return id.toUpperCase();
  }

  static String formatDensityPercent(double v) {
    final percent = (v * 100).clamp(0, 100).toInt();
    return '$percent%';
  }
}
