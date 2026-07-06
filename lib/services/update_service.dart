import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fetched from `app_config` in Supabase. Represents the server-side update policy.
class _AppConfig {
  final String updateMode;
  final int minimumVersionCode;
  final int latestVersionCode;
  final bool maintenance;

  const _AppConfig({
    required this.updateMode,
    required this.minimumVersionCode,
    required this.latestVersionCode,
    required this.maintenance,
  });

  factory _AppConfig.fromMap(Map<String, dynamic> map) {
    return _AppConfig(
      updateMode: map['update_mode'] as String? ?? 'flexible',
      minimumVersionCode: map['minimum_version_code'] as int? ?? 1,
      latestVersionCode: map['latest_version_code'] as int? ?? 1,
      maintenance: map['maintenance'] as bool? ?? false,
    );
  }
}

/// Handles checking for Play Store app updates using a remote configuration
/// stored in Supabase (`app_config` table) and `in_app_update` for Play Store
/// update delivery.
///
/// Decision logic:
///   - If Play Store reports no update → skip.
///   - If `currentVersionCode < minimumVersionCode` → IMMEDIATE update (blocking).
///   - Otherwise → FLEXIBLE update (non-blocking, downloads in background).
///
/// Usage:
///   ```dart
///   await UpdateService.instance.checkForUpdates();
///   ```
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  /// Checks for an available app update and triggers the appropriate flow.
  ///
  /// Safe to call on non-Android platforms or in debug mode — it will return
  /// immediately without doing anything.
  Future<void> checkForUpdates() async {
    // In-app update only works on Android, and only in production (Play Store installs).
    // Skip gracefully in debug mode or on non-Android platforms.
    if (!Platform.isAndroid || kDebugMode) {
      debugPrint('[UpdateService] Skipping update check (not Android or debug mode).');
      return;
    }

    try {
      // 1. Read installed versionCode (build number)
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;
      debugPrint('[UpdateService] Current versionCode: $currentVersionCode');

      // 2. Fetch remote policy from Supabase app_config
      _AppConfig? config;
      try {
        final response = await Supabase.instance.client
            .from('app_config')
            .select()
            .eq('id', 1)
            .maybeSingle();
        if (response != null) {
          config = _AppConfig.fromMap(response);
          debugPrint(
            '[UpdateService] Remote config → mode: ${config.updateMode}, '
            'min: ${config.minimumVersionCode}, latest: ${config.latestVersionCode}',
          );
        }
      } catch (e) {
        // Supabase fetch failed — fall through without a forced update.
        debugPrint('[UpdateService] Failed to fetch app_config: $e');
      }

      // 3. Ask Play Store if an update is available
      AppUpdateInfo updateInfo;
      try {
        updateInfo = await InAppUpdate.checkForUpdate();
      } catch (e) {
        debugPrint('[UpdateService] Play Store update check failed: $e');
        return;
      }

      if (updateInfo.updateAvailability != UpdateAvailability.updateAvailable) {
        debugPrint('[UpdateService] No Play Store update available.');
        return;
      }

      debugPrint('[UpdateService] Play Store update available. Deciding flow...');

      // 4. Decide immediate vs flexible
      final shouldForce = config != null &&
          currentVersionCode < config.minimumVersionCode;

      if (shouldForce) {
        debugPrint('[UpdateService] Triggering IMMEDIATE update (currentVersionCode $currentVersionCode < minimum ${config!.minimumVersionCode}).');
        await _performImmediateUpdate();
      } else {
        debugPrint('[UpdateService] Triggering FLEXIBLE update.');
        await _performFlexibleUpdate();
      }
    } catch (e) {
      // Never crash the app due to an update check failure.
      debugPrint('[UpdateService] Unexpected error during update check: $e');
    }
  }

  /// Triggers a blocking immediate update. The user cannot bypass this.
  /// If it fails or is cancelled, we exit the app (since the version is below minimum).
  Future<void> _performImmediateUpdate() async {
    try {
      await InAppUpdate.performImmediateUpdate();
      // If we reach here, the update was applied — the system usually restarts the app.
    } catch (e) {
      debugPrint('[UpdateService] Immediate update failed: $e');
      // Version is below minimum — if the update fails, we must exit.
      exit(0);
    }
  }

  /// Triggers a non-blocking flexible update. Downloads in the background
  /// and installs when complete. The user can continue using the app.
  Future<void> _performFlexibleUpdate() async {
    try {
      await InAppUpdate.startFlexibleUpdate();
      debugPrint('[UpdateService] Flexible update download started.');
      // Listen for the download to complete and then prompt install.
      await InAppUpdate.completeFlexibleUpdate();
      debugPrint('[UpdateService] Flexible update installed.');
    } catch (e) {
      // Flexible update failure is non-fatal — user can continue using the app.
      debugPrint('[UpdateService] Flexible update failed or was dismissed: $e');
    }
  }
}
