import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls the app's appearance mode (system / light / dark), persisting
/// the user's choice to SharedPreferences. Intended to be provided at the
/// root of the widget tree via a [ChangeNotifierProvider].
class AppearanceController extends ChangeNotifier {
  static const _prefsKey = 'appearance.mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  /// Load the persisted mode. Call once at app start before using [mode].
  ///
  /// Emits one notification on completion so that any consumer that already
  /// subscribed (e.g., `MaterialApp.themeMode` via a `Consumer`) rebuilds
  /// once the stored preference resolves. Without this, a returning user
  /// with a stored `light`/`dark` preference sees the first frame render
  /// in `system` mode.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final parsed = _parse(prefs.getString(_prefsKey));
    if (parsed == _mode) return;
    _mode = parsed;
    notifyListeners();
  }

  /// Update the mode, persist it, and notify listeners. No-op if unchanged.
  Future<void> setMode(ThemeMode newMode) async {
    if (newMode == _mode) return;
    _mode = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _encode(newMode));
    notifyListeners();
  }

  static ThemeMode _parse(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
