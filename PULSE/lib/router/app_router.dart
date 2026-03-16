import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_ev/features/auth/providers/auth_provider.dart';
import 'package:pulse_ev/features/auth/screens/login_screen.dart';
import 'package:pulse_ev/features/auth/screens/signup_screen.dart';
import 'package:pulse_ev/features/auth/screens/splash_screen.dart';
import 'package:pulse_ev/features/dashboard/screens/dashboard_screen.dart';
import 'package:pulse_ev/features/mission/screens/mission_setup_screen.dart';
import 'package:pulse_ev/features/mission/screens/mission_summary_screen.dart';
import 'package:pulse_ev/features/mission/screens/destination_picker_screen.dart';
import 'package:pulse_ev/features/navigation/screens/live_map_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggingIn = state.uri.path == '/login';
      final isSigningUp = state.uri.path == '/signup';
      final isSplash = state.uri.path == '/splash';

      if (authState == AuthState.unauthenticated) {
        if (isLoggingIn || isSigningUp || isSplash) return null;
        return '/login';
      }

      if (authState == AuthState.authenticated) {
        if (isLoggingIn || isSigningUp) return '/dashboard';
      }

      return null;
    },
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
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/mission/setup',
        builder: (context, state) => const MissionSetupScreen(),
      ),
      GoRoute(
        path: '/mission/pick-destination',
        builder: (context, state) => const DestinationPickerScreen(),
      ),
      GoRoute(
        path: '/mission/active',
        builder: (context, state) => const LiveMapScreen(),
      ),
      GoRoute(
        path: '/mission/summary',
        builder: (context, state) => const MissionSummaryScreen(),
      ),
    ],
  );
});
