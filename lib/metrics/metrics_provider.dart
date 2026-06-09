import 'package:flutter/foundation.dart';
import 'metrics_api_client.dart';
import 'metrics_models.dart';

/// In-app cache + orchestration for metrics.
class MetricsProvider extends ChangeNotifier {
  final MetricsApiClient _client;

  MetricsSnapshot? _snapshot;
  MetricsSnapshot? _previousSnapshot;
  DateTime? _lastFetchedAt;
  bool _loading = false;
  Object? _lastError;

  MetricsProvider({required MetricsApiClient client}) : _client = client;

  MetricsSnapshot? get snapshot => _snapshot;

  /// The snapshot we had immediately before the most recent successful refresh.
  /// Used by the PR hero banner to compute a delta vs the prior best.
  /// Null on first ever refresh and after [clear].
  MetricsSnapshot? get previousSnapshot => _previousSnapshot;

  bool get hasData => _snapshot != null;
  bool get loading => _loading;
  Object? get lastError => _lastError;

  /// Fetch from API if cached value is older than [maxAge]. No-op otherwise.
  Future<void> refresh({Duration maxAge = const Duration(minutes: 5)}) async {
    // Guard against concurrent fetches: if a refresh is already in flight,
    // skip this call. The in-flight call will eventually notify all listeners.
    if (_loading) return;
    if (!_isStale(maxAge)) return;
    _loading = true;
    notifyListeners();
    try {
      final newSnapshot = await _client.fetchSnapshot();
      // Stash AFTER the fetch succeeds — a failed fetch must not touch the
      // previousSnapshot/snapshot relationship.
      _previousSnapshot = _snapshot;
      _snapshot = newSnapshot;
      _lastFetchedAt = DateTime.now();
      _lastError = null;
    } catch (e) {
      _lastError = e;
      // Keep prior snapshot AND previousSnapshot on error.
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
    _previousSnapshot = null;
    _lastFetchedAt = null;
    _lastError = null;
    notifyListeners();
  }

  bool _isStale(Duration maxAge) {
    if (_snapshot == null || _lastFetchedAt == null) return true;
    return DateTime.now().difference(_lastFetchedAt!) > maxAge;
  }
}
