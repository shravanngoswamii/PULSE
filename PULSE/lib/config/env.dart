import 'package:flutter/foundation.dart' show kIsWeb;

class Env {
  // For web (Chrome): use localhost. For Android emulator: use 10.0.2.2
  static String get apiBaseUrl =>
      kIsWeb ? 'http://localhost:9000/api' : 'http://10.0.2.2:9000/api';

  static String get websocketUrl =>
      kIsWeb ? 'ws://localhost:9000/ws' : 'ws://10.0.2.2:9000/ws';

  static const int requestTimeout = 30000;
  static const String appEnvironment = 'development';
}
