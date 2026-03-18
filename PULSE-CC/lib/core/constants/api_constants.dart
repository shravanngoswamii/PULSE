import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  static String get _host {
    final fromEnv = dotenv.maybeGet('API_HOST');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'localhost';
    return 'localhost';
  }

  static int get _port {
    final fromEnv = dotenv.maybeGet('API_PORT');
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return int.tryParse(fromEnv) ?? 9000;
    }
    return 9000;
  }

  static String get baseUrl => 'http://$_host:$_port/api';

  static String get wsUrl => 'ws://$_host:$_port/ws/operator';

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
