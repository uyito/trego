import 'package:flutter/foundation.dart';
import 'metrics_api_client.dart';
import 'metrics_models.dart';

/// In-app cache + orchestration for metrics.
class MetricsProvider extends ChangeNotifier {
  final MetricsApiClient _client;

  MetricsSnapshot? _snapshot;
  DateTime? _lastFetchedAt;
  bool _loading = false;
  Object? _lastError;

  MetricsProvider({required MetricsApiClient client}) : _client = client;

  MetricsSnapshot? get snapshot => _snapshot;
  bool get hasData => _snapshot != null;
  bool get loading => _loading;
  Object? get lastError => _lastError;

  /// Fetch from API if cached value is older than [maxAge]. No-op otherwise.
  Future<void> refresh({Duration maxAge = const Duration(minutes: 5)}) async {
    if (!_isStale(maxAge)) return;
    _loading = true;
    notifyListeners();
    try {
      _snapshot = await _client.fetchSnapshot();
      _lastFetchedAt = DateTime.now();
      _lastError = null;
    } catch (e) {
      _lastError = e;
      // Keep prior snapshot on error.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Trigger backend recompute, then re-fetch.
  /// Recompute failure is swallowed — backend's stale-fallback handles it.
  Future<void> recomputeAndRefresh() async {
    try {
      await _client.recompute();
    } catch (_) {
      // Backend lazy-fallback will handle next read.
    }
    _lastFetchedAt = null; // force fresh fetch
    await refresh(maxAge: Duration.zero);
  }

  /// Drop cached state — call on sign-out.
  void clear() {
    _snapshot = null;
    _lastFetchedAt = null;
    _lastError = null;
    notifyListeners();
  }

  bool _isStale(Duration maxAge) {
    if (_snapshot == null || _lastFetchedAt == null) return true;
    return DateTime.now().difference(_lastFetchedAt!) > maxAge;
  }
}
