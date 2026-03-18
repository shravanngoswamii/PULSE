import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/router/app_router.dart';
import 'package:pulse_ev/shared/widgets/dispatch_overlay.dart';

class PulseApp extends ConsumerWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'PULSE',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Wrap the entire app with the dispatch overlay so
        // emergency notifications appear on ANY screen
        return DispatchOverlay(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
