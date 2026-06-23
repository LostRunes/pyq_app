import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/app_initializer.dart';
import 'core/providers.dart';

void main() async {
  final prefs = await AppInitializer.initialize();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const PyqApp(),
    ),
  );
}
