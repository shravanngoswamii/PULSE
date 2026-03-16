class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.pulse.city/v1';
  static const String wsUrl = 'wss://api.pulse.city/v1/live';
  static const String mqttBroker = 'mqtt.pulse.city';
  static const int mqttPort = 1883;
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration wsReconnectDelay = Duration(seconds: 5);

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // Missions
  static const String activeMissions = '/missions/active';
  static const String missionById = '/missions/{id}';

  // Intersections
  static const String intersections = '/intersections';
  static const String intersectionById = '/intersections/{id}';
  static const String forceSignal = '/intersections/{id}/signal';
  static const String restoreAuto = '/intersections/{id}/restore';

  // Alerts
  static const String alerts = '/alerts';
  static const String clearAlert = '/alerts/{id}/clear';

  // Intelligence
  static const String trafficStats = '/intelligence/stats';
  static const String districtView = '/intelligence/district/{sector}';

  // Simulation
  static const String simStart = '/simulation/start';
  static const String simStop = '/simulation/stop';
  static const String simReset = '/simulation/reset';
}
