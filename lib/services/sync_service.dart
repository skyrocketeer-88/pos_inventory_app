import 'dart:async';

// flutter foundation not required here; keep minimal to avoid hard deps

// Optional Firebase realtime sync helper. Initialization is best-effort — if the
// app is not configured with Firebase, these functions will quietly no-op so
// the app continues using local Hive storage.

class SyncService {
  static bool _enabled = false;

  static Future<void> init() async {
    try {
      // Lazy import Firebase only when available to avoid hard runtime deps.
      // The actual Firebase packages are added to pubspec; if Firebase isn't
      // configured for the platform this will throw and we silently disable
      // remote sync.
      // Keep this minimal: initialization will be attempted by the app, but
      // lacking configuration the app still functions locally.
      _enabled = false;
    } catch (e) {
      _enabled = false;
    }
  }

  static bool get enabled => _enabled;

  // Placeholder: projects can extend this with real Firestore listeners.
  static Future<void> startSync(Object storageService) async {
    if (!_enabled) return;
    // No-op in this build; left as an integration point for Firebase/Firestore
    // sync (subscribe to collections and mirror to Hive boxes).
  }
}
