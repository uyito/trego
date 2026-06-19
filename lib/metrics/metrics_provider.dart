import 'package:flutter/foundation.dart';
import 'metrics_api_client.dart';
import 'metrics_models.dart';

/// In-app cache + orchestration for metrics.
class MetricsProvider extends ChangeNotifier {
  final MetricsApiClient _client;

  MetricsSnapshot? _snapshot;
  MetricsSnapshot? _previousSnapshot;
  WeeklyGoal? _goal;
  DateTime? _lastFetchedAt;
  bool _loading = false;
  Object? _lastError;

  /// Bumped by [clear] (and any other state-resetting operation). Captured by
  /// [refresh] before awaiting; refresh discards its result if the counter
  /// changed mid-flight. Race-proof against clear-while-fetching.
  int _refreshGeneration = 0;

  MetricsProvider({required MetricsApiClient client}) : _client = client;

  MetricsSnapshot? get snapshot => _snapshot;

  /// The snapshot we had immediately before the most recent successful refresh.
  /// Used by the PR hero banner to compute a delta vs the prior best.
  /// Null on first ever refresh and after [clear].
  MetricsSnapshot? get previousSnapshot => _previousSnapshot;

  /// The user's weekly goal. Null until first fetched; an all-null [WeeklyGoal]
  /// once fetched with nothing set.
  WeeklyGoal? get goal => _goal;

  bool get hasData => _snapshot != null;
  bool get loading => _loading;
  Object? get lastError => _lastError;

  /// Fetch from API if cached value is older than [maxAge]. No-op otherwise.
  Future<void> refresh({Duration maxAge = const Duration(minutes: 5)}) async {
    // Guard against concurrent fetches: if a refresh is already in flight,
    // skip this call. The in-flight call will eventually notify all listeners.
    if (_loading) return;
    if (!_isStale(maxAge)) return;
    final myGen = _refreshGeneration;
    _loading = true;
    notifyListeners();
    try {
      final newSnapshot = await _client.fetchSnapshot();
      // If clear() (or another resetter) bumped the generation while we were
      // in flight, discard this result — the state was intentionally reset.
      if (myGen != _refreshGeneration) return;
      // Stash AFTER the fetch succeeds — a failed fetch must not touch the
      // previousSnapshot/snapshot relationship.
      _previousSnapshot = _snapshot;
      _snapshot = newSnapshot;
      _lastFetchedAt = DateTime.now();
      _lastError = null;
      // Goal is best-effort and must not fail the snapshot refresh.
      try {
        final goal = await _client.fetchGoal();
        if (myGen == _refreshGeneration) _goal = goal;
      } catch (_) {
        // Leave the prior goal in place.
      }
    } catch (e) {
      if (myGen != _refreshGeneration) return;
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

  /// Set the user's weekly goal (optimistic). Reverts on failure.
  Future<void> setGoal({double? targetKm, int? targetRuns}) async {
    final previous = _goal;
    _goal = WeeklyGoal(targetKm: targetKm, targetRuns: targetRuns);
    notifyListeners();
    try {
      _goal = await _client.updateGoal(targetKm: targetKm, targetRuns: targetRuns);
    } catch (e) {
      _goal = previous; // revert
      _lastError = e;
    } finally {
      notifyListeners();
    }
  }

  /// Drop cached state — call on sign-out. Any in-flight [refresh] will
  /// observe the bumped generation and discard its result.
  void clear() {
    _refreshGeneration++;
    _snapshot = null;
    _previousSnapshot = null;
    _goal = null;
    _lastFetchedAt = null;
    _lastError = null;
    notifyListeners();
  }

  bool _isStale(Duration maxAge) {
    if (_snapshot == null || _lastFetchedAt == null) return true;
    return DateTime.now().difference(_lastFetchedAt!) > maxAge;
  }
}
