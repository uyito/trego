import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../metrics/metrics_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../tracker/auto_pause_detector.dart';
import '../../tracker/pending_saves_flusher.dart';
import '../../tracker/record_preferences.dart';
import '../../tracker/record_state.dart';
import '../../tracker/run_model.dart';
import '../../tracker/run_service.dart';
import '../../tracker/session_controller.dart';
import 'countdown_overlay.dart';
import 'live_record_screen.dart';
import 'pre_start_screen.dart';
import 'stop_confirm_screen.dart';
import 'summary_screen.dart';

/// Root route for the Record flow. Hosts a nested [Navigator] and owns a
/// [SessionController] scoped to a single session. Acquires the wakelock on
/// entry and releases it on exit so the screen stays awake while recording.
class RecordFlow extends StatefulWidget {
  const RecordFlow({super.key});

  @override
  State<RecordFlow> createState() => _RecordFlowState();
}

class _RecordFlowState extends State<RecordFlow> {
  late final SessionController _controller;
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    final userId =
        (context.read<AppStateProvider>().user?['uid'] as String?) ??
            'anonymous';
    _controller = SessionController(
      runService: _RunServiceAdapter(RunService()),
      prefs: context.read<RecordPreferences>(),
      autoPauseDetector: AutoPauseDetector(),
      pendingSavesFlusher: context.read<PendingSavesFlusher>(),
      currentUserId: userId,
    )..addListener(_onStateChange);
    _controller.enterFlow();
    WakelockPlus.enable();
  }

  void _onStateChange() {
    final nav = _navKey.currentState;
    if (nav == null) return;

    switch (_controller.state) {
      case RecordState.idle:
        // Flow done — pop the outer (root) route back to the shell.
        Navigator.of(context, rootNavigator: true).maybePop();
        break;
      case RecordState.preStart:
        break;
      case RecordState.countdown:
        nav.pushReplacement(MaterialPageRoute(
          builder: (_) => const CountdownOverlay(),
        ));
        break;
      case RecordState.recording:
        nav.pushReplacement(MaterialPageRoute(
          builder: (_) => const LiveRecordScreen(),
        ));
        break;
      case RecordState.paused:
        // Same screen; it reacts to controller state.
        break;
      case RecordState.confirming:
        nav.push(MaterialPageRoute(
          builder: (_) => const StopConfirmScreen(),
        ));
        break;
      case RecordState.saving:
        // Still on StopConfirm; controller advances automatically.
        break;
      case RecordState.summary:
        // Trigger backend metrics recompute. Fire-and-forget; failure is
        // handled by the backend's stale-fallback on next read.
        context.read<MetricsProvider>().recomputeAndRefresh();
        nav.pushReplacement(MaterialPageRoute(
          builder: (_) => const SummaryScreen(),
        ));
        break;
      case RecordState.error:
        // Error dialogs are shown by the screen that triggered them.
        break;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChange);
    _controller.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SessionController>.value(
      value: _controller,
      child: Navigator(
        key: _navKey,
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => const PreStartScreen(),
        ),
      ),
    );
  }
}

/// Thin adapter exposing only what [SessionController] needs from
/// [RunService]. RunService's startRun/stopRun signatures predate the
/// interface, so the wrapper normalises them:
///   - startRun(userId) → calls the no-arg startRun(); userId is ignored
///     because RunService reads the uid from AuthService internally.
///   - stopRun() → returns a non-null Run; if RunService returns null
///     (no active run), we synthesise an empty Run so the contract holds.
class _RunServiceAdapter implements SessionRunService {
  final RunService _inner;
  _RunServiceAdapter(this._inner);

  @override
  Future<void> startRun(String userId) async {
    await _inner.startRun();
  }

  @override
  Future<void> pauseRun() => _inner.pauseRun();

  @override
  Future<void> resumeRun() => _inner.resumeRun();

  @override
  Future<Run> stopRun() async {
    // saveOnStop: false — the Record flow's PendingSavesFlusher is the
    // sole writer for finished runs; the legacy internal save would
    // produce a duplicate Firestore document.
    final run = await _inner.stopRun(saveOnStop: false);
    if (run != null) return run;
    // Defensive fallback: stopRun() returns null only if no run was active,
    // which shouldn't happen on the SessionController code path.
    final now = DateTime.now();
    return Run(
      userId: '',
      startTime: now,
      endTime: now,
      duration: Duration.zero,
      distance: 0,
      averagePace: 0,
      route: const [],
    );
  }

  @override
  Duration get elapsed => _inner.currentDuration;

  @override
  double get distanceKm => _inner.currentDistanceKm;

  @override
  Duration? get currentPacePerKm => _inner.currentPacePerKm;

  @override
  List<LatLng> get route => _inner.currentRoute;

  @override
  double? get accuracyMeters => _inner.currentAccuracyMeters;

  @override
  Stream<Object> get errorStream => _inner.errorStream;
}

/// Listens to a session-state notifier and, on transition to
/// [RecordState.summary], invokes `MetricsProvider.recomputeAndRefresh()`
/// exactly once per transition. Generic over the notifier type so tests
/// can substitute a fake without depending on [SessionController]'s full
/// surface. Used by [RecordFlow] internally and by tests directly.
class RecordFlowSummaryHook<T extends ChangeNotifier> extends StatefulWidget {
  final RecordState Function(T notifier) stateOf;
  final Widget child;

  const RecordFlowSummaryHook({
    super.key,
    required this.stateOf,
    this.child = const SizedBox.shrink(),
  });

  @override
  State<RecordFlowSummaryHook<T>> createState() =>
      _RecordFlowSummaryHookState<T>();
}

class _RecordFlowSummaryHookState<T extends ChangeNotifier>
    extends State<RecordFlowSummaryHook<T>> {
  RecordState? _last;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<T>();
    final current = widget.stateOf(notifier);
    if (current == RecordState.summary && _last != RecordState.summary) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<MetricsProvider>().recomputeAndRefresh();
      });
    }
    _last = current;
    return widget.child;
  }
}
