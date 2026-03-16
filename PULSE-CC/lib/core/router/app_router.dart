import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/live_map/screens/live_map_screen.dart';
import '../../features/emergencies/screens/emergency_monitor_screen.dart';
import '../../features/emergencies/screens/alerts_screen.dart';
import '../../features/intelligence/screens/intelligence_screen.dart';
import '../../features/simulation/screens/simulation_screen.dart';
import '../../features/intersection_control/screens/intersection_control_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/live-map',
        builder: (context, state) => const LiveMapScreen(),
        routes: [
          GoRoute(
            path: 'intersection/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return IntersectionControlScreen(intersectionId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/intersection-control',
        builder: (context, state) => const IntersectionControlScreen(intersectionId: 'INT-001'),
      ),
      GoRoute(
        path: '/emergencies',
        builder: (context, state) => const EmergencyMonitorScreen(),
        routes: [
          GoRoute(
            path: 'alerts',
            builder: (context, state) => const AlertsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/intelligence',
        builder: (context, state) => const IntelligenceScreen(),
      ),
      GoRoute(
        path: '/simulation',
        builder: (context, state) => const SimulationScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
