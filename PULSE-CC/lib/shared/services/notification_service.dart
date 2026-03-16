import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationService {
  void showEmergencyAlert(String title, String body) {
    if (kDebugMode) {
      print('🔔 ALERT: $title - $body');
    }
  }

  void showSignalOverrideConfirmation(String intersectionName) {
    if (kDebugMode) {
      print('🚦 SIGNAL OVERRIDE: $intersectionName');
    }
  }

  void showMissionUpdate(String vehicleId, String message) {
    if (kDebugMode) {
      print('🚑 MISSION UPDATE [$vehicleId]: $message');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
