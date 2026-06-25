import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/app_initializer.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/providers/prefs_provider.dart';

void main() async {
  usePathUrlStrategy();
  final prefs = await AppInitializer.initialize();

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const PyqApp(),
    ),
  );
}
