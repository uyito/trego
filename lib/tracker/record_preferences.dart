import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Recording settings persisted to SharedPreferences.
/// Default: auto-pause ON (matches Strava / Nike behavior).
class RecordPreferences extends ChangeNotifier {
  static const _autoPauseKey = 'recording.autoPause';

  bool _autoPauseEnabled = true;
  bool get autoPauseEnabled => _autoPauseEnabled;

  /// Load the persisted value. Call once at app start.
  /// Emits one notification if the stored value differs from the default.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_autoPauseKey) ?? true;
    if (stored == _autoPauseEnabled) return;
    _autoPauseEnabled = stored;
    notifyListeners();
  }

  /// Update and persist. No-op (no notification) if unchanged.
  Future<void> setAutoPauseEnabled(bool value) async {
    if (value == _autoPauseEnabled) return;
    _autoPauseEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoPauseKey, value);
    notifyListeners();
  }
}
