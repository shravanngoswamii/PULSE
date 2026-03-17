import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  /// Call this once in main() before runApp:
  ///   await Env.load();
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  /// The host portion of the backend URL.
  ///   - Reads API_HOST from .env
  ///   - Falls back to platform-sensible defaults:
  ///       Web           → localhost
  ///       iOS Simulator → localhost  (same machine as Mac)
  ///       Android Emul. → 10.0.2.2  (loopback to host)
  static String get _host {
    final fromEnv = dotenv.maybeGet('API_HOST');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'localhost';
    // Heuristic: on Android the platform is always 'android';
    // iOS Simulator also works with localhost.
    return 'localhost';
  }

  static int get _port {
    final fromEnv = dotenv.maybeGet('API_PORT');
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return int.tryParse(fromEnv) ?? 9000;
    }
    return 9000;
  }

  static String get apiBaseUrl => 'http://$_host:$_port/api';

  static String get websocketUrl => 'ws://$_host:$_port/ws';

  static const int requestTimeout = 30000;
  static const String appEnvironment = 'development';
}
