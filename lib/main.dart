import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/sqlite_init.dart';

Future<void> bootstrap() async {
  initSqliteFactory();
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
