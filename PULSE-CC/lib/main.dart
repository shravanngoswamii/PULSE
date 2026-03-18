import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/api_constants.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConstants.load();
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
