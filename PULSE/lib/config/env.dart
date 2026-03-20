import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  static String get apiBaseUrl {
    final fullUrl = dotenv.maybeGet('API_BASE_URL');
    if (fullUrl != null && fullUrl.isNotEmpty) {
      final trimmed = fullUrl.endsWith('/') ? fullUrl.substring(0, fullUrl.length - 1) : fullUrl;
      return '$trimmed/api';
    }
    return 'http://$_host:$_port/api';
  }

  static String get websocketUrl {
    final fullUrl = dotenv.maybeGet('API_BASE_URL');
    if (fullUrl != null && fullUrl.isNotEmpty) {
      final trimmed = fullUrl.endsWith('/') ? fullUrl.substring(0, fullUrl.length - 1) : fullUrl;
      final wsScheme = trimmed.startsWith('https') ? 'wss' : 'ws';
      return '$wsScheme${trimmed.substring(trimmed.indexOf('://'))}/ws';
    }
    return 'ws://$_host:$_port/ws';
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

  static const int requestTimeout = 30000;
  static const String appEnvironment = 'development';
}
