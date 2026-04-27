import 'dart:async';
import 'package:flutter/foundation.dart';
import 'auto_pause_detector.dart';
import 'pending_saves_flusher.dart';
import 'record_preferences.dart';
import 'record_state.dart';
import 'run_model.dart';

/// Minimal slice of RunService that SessionController uses.
/// Defined as an interface so tests can inject a fake.
abstract class SessionRunService {
  Future<void> startRun(String userId);
  Future<void> pauseRun();
  Future<void> resumeRun();
  Future<Run> stopRun();
  Duration get elapsed;
  double get distanceKm;
  Duration? get currentPacePerKm;
  List<LatLng> get route;
  double? get accuracyMeters;
  Stream<Object> get errorStream;
}

class SessionController extends ChangeNotifier {
  final SessionRunService _svc;
  final RecordPreferences _prefs;
  final AutoPauseDetector _detector;
  final PendingSavesFlusher _flusher;
  final String _userId;

  RecordState _state = RecordState.idle;
  PauseReason? _pauseReason;
  RecordError? _error;
  bool _offlineQueued = false;
  Run? _lastRun;

  SessionController({
    required SessionRunService runService,
    required RecordPreferences prefs,
    required AutoPauseDetector autoPauseDetector,
    required PendingSavesFlusher pendingSavesFlusher,
    required String currentUserId,
  })  : _svc = runService,
        _prefs = prefs,
        _detector = autoPauseDetector,
        _flusher = pendingSavesFlusher,
        _userId = currentUserId {
    _detector
      ..onPauseRequested = _onAutoPause
      ..onResumeRequested = _onAutoResume;
  }

  RecordState get state => _state;
  PauseReason? get pauseReason => _pauseReason;
  RecordError? get error => _error;
  bool get offlineQueued => _offlineQueued;
  Run? get lastRun => _lastRun;

  // Metrics pass-through
  Duration get elapsed => _svc.elapsed;
  double get distanceKm => _svc.distanceKm;
  Duration? get currentPacePerKm => _svc.currentPacePerKm;
  List<LatLng> get route => _svc.route;
  double? get currentAccuracyMeters => _svc.accuracyMeters;

  // --- Transitions ---

  void enterFlow() => _go(RecordState.preStart);

  void cancelFlow() {
    _detector.disable();
    _go(RecordState.idle);
  }

  void startCountdown() {
    if (_state != RecordState.preStart) return;
    _go(RecordState.countdown);
  }

  void cancelCountdown() {
    if (_state != RecordState.countdown) return;
    _go(RecordState.idle);
  }

  void countdownComplete() {
    if (_state != RecordState.countdown) return;
    _svc.startRun(_userId);
    if (_prefs.autoPauseEnabled) _detector.enable();
    _go(RecordState.recording);
  }

  void pauseManual() {
    if (_state != RecordState.recording) return;
    _svc.pauseRun();
    _pauseReason = PauseReason.manual;
    _go(RecordState.paused);
  }

  void _onAutoPause() {
    if (_state != RecordState.recording) return;
    _svc.pauseRun();
    _pauseReason = PauseReason.auto;
    _go(RecordState.paused);
  }

  void _onAutoResume() {
    if (_state != RecordState.paused || _pauseReason != PauseReason.auto) return;
    _svc.resumeRun();
    _pauseReason = null;
    _go(RecordState.recording);
  }

  void resume() {
    if (_state != RecordState.paused) return;
    _svc.resumeRun();
    _pauseReason = null;
    _go(RecordState.recording);
  }

  void requestStop() {
    if (_state != RecordState.recording && _state != RecordState.paused) return;
    if (_state == RecordState.recording) _svc.pauseRun();
    _go(RecordState.confirming);
  }

  void discard() {
    if (_state != RecordState.confirming) return;
    _detector.disable();
    _go(RecordState.idle);
  }

  Future<void> finish() async {
    if (_state != RecordState.confirming) return;
    _go(RecordState.saving);
    final run = await _svc.stopRun();
    _lastRun = run;
    _detector.disable();
    try {
      await _flusher.enqueue(run); // enqueue first for durability
      // Then try an immediate flush; on success the queue drains.
      await _flusher.flush();
      _offlineQueued = _flusher.pendingCount > 0;
    } catch (_) {
      _offlineQueued = true;
    }
    _go(RecordState.summary);
  }

  void exitSummary() {
    if (_state != RecordState.summary) return;
    _go(RecordState.idle);
  }

  void reportPermissionDenied({required bool permanent}) {
    _error = permanent
        ? RecordError.permissionPermanentlyDenied
        : RecordError.permissionDenied;
    _go(RecordState.error);
  }

  void reportGpsUnavailable() {
    _error = RecordError.gpsUnavailable;
    _go(RecordState.error);
  }

  void dismissError() {
    _error = null;
    _go(RecordState.idle);
  }

  void _go(RecordState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _detector.disable();
    super.dispose();
  }
}
