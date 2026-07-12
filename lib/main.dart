import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

/// Placeholder for any pre-launch setup (env config, crash reporting,
/// etc.). Nothing is required for this app to run against the
/// Vibe Connect API, but this keeps the door open without touching
/// main() again later.
Future<void> bootstrap() async {
  return;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();
  runApp(
    const ProviderScope(
      child: VibeConnectApp(),
    ),
  );
}
