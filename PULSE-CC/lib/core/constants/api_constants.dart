import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  static String get _host {
    if (kIsWeb) return 'localhost';
    // Android emulator uses 10.0.2.2 to reach host machine;
    // iOS simulator uses localhost directly.
    try {
      return Platform.isAndroid ? '10.0.2.2' : 'localhost';
    } catch (_) {
      return 'localhost';
    }
  }

  static String get baseUrl => 'http://$_host:9000/api';

  static String get wsUrl => 'ws://$_host:9000/ws/operator';

  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration wsReconnectDelay = Duration(seconds: 5);

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Operator
  static const String operatorState = '/operator/state';
  static const String missions = '/operator/missions';
  static const String intersections = '/operator/intersections';
  static const String alerts = '/operator/alerts';
}
