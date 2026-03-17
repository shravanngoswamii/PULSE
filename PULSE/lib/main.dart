import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_ev/app.dart';
import 'package:pulse_ev/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env before anything else so Env.apiBaseUrl is ready
  await Env.load();

  runApp(
    const ProviderScope(
      child: PulseApp(),
    ),
  );
}
