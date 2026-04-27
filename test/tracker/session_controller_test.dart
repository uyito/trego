import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trego/tracker/auto_pause_detector.dart';
import 'package:trego/tracker/pending_saves_flusher.dart';
import 'package:trego/tracker/record_preferences.dart';
import 'package:trego/tracker/record_state.dart';
import 'package:trego/tracker/run_model.dart';
import 'package:trego/tracker/session_controller.dart';

class FakeRunService implements SessionRunService {
  bool started = false, paused = false, stopped = false;
  Duration elapsed = Duration.zero;
  double distanceKm = 0;
  Duration? currentPacePerKm;
  List<LatLng> route = [];
  double? accuracyMeters;
  final _err = StreamController<Object>.broadcast();

  @override
  Future<void> startRun(String userId) async { started = true; }
  @override
  Future<void> pauseRun() async { paused = true; }
  @override
  Future<void> resumeRun() async { paused = false; }
  @override
  Future<Run> stopRun() async {
    stopped = true;
    return Run(
      userId: 'u',
      startTime: DateTime.fromMillisecondsSinceEpoch(0),
      endTime: DateTime.fromMillisecondsSinceEpoch(elapsed.inMilliseconds),
      duration: elapsed,
      distance: distanceKm,
      averagePace: 6,
      route: route,
    );
  }

  @override Stream<Object> get errorStream => _err.stream;
}

class FakeSaver implements RunSaver {
  bool shouldFail = false;
  final saved = <Run>[];
  @override Future<void> save(Run run) async {
    if (shouldFail) throw Exception('no net');
    saved.add(run);
  }
}

SessionController _build({FakeRunService? svc, FakeSaver? saver}) {
  SharedPreferences.setMockInitialValues({});
  svc ??= FakeRunService();
  saver ??= FakeSaver();
  final prefs = RecordPreferences();
  return SessionController(
    runService: svc,
    prefs: prefs,
    autoPauseDetector: AutoPauseDetector(),
    pendingSavesFlusher: PendingSavesFlusher(saver: saver),
    currentUserId: 'u',
  );
}

void main() {
  test('initial state is idle', () {
    expect(_build().state, RecordState.idle);
  });

  test('enterFlow moves to preStart', () async {
    final c = _build();
    c.enterFlow();
    expect(c.state, RecordState.preStart);
  });

  test('startCountdown moves preStart -> countdown', () async {
    final c = _build()..enterFlow();
    c.startCountdown();
    expect(c.state, RecordState.countdown);
  });

  test('cancelCountdown returns to idle', () async {
    final c = _build()..enterFlow();
    c.startCountdown();
    c.cancelCountdown();
    expect(c.state, RecordState.idle);
  });

  test('countdownComplete moves to recording and calls startRun', () async {
    final svc = FakeRunService();
    final c = _build(svc: svc)..enterFlow();
    c.startCountdown();
    c.countdownComplete();
    expect(c.state, RecordState.recording);
    expect(svc.started, isTrue);
  });

  test('pauseManual moves recording -> paused(manual) and calls pauseRun', () async {
    final svc = FakeRunService();
    final c = _build(svc: svc)..enterFlow();
    c.startCountdown();
    c.countdownComplete();
    c.pauseManual();
    expect(c.state, RecordState.paused);
    expect(c.pauseReason, PauseReason.manual);
    expect(svc.paused, isTrue);
  });

  test('resume from paused returns to recording', () async {
    final svc = FakeRunService();
    final c = _build(svc: svc)..enterFlow();
    c.startCountdown();
    c.countdownComplete();
    c.pauseManual();
    c.resume();
    expect(c.state, RecordState.recording);
    expect(svc.paused, isFalse);
  });

  test('requestStop from recording moves to confirming', () async {
    final c = _build()..enterFlow();
    c.startCountdown();
    c.countdownComplete();
    c.requestStop();
    expect(c.state, RecordState.confirming);
  });

  test('requestStop from paused also moves to confirming', () async {
    final c = _build()..enterFlow();
    c.startCountdown();
    c.countdownComplete();
    c.pauseManual();
    c.requestStop();
    expect(c.state, RecordState.confirming);
  });

  test('finish moves confirming -> saving -> summary (success)', () async {
    final svc = FakeRunService();
    final saver = FakeSaver();
    final c = _build(svc: svc, saver: saver)..enterFlow();
    c.startCountdown();
    c.countdownComplete();
    c.requestStop();
    await c.finish();
    expect(c.state, RecordState.summary);
    expect(c.offlineQueued, isFalse);
    expect(saver.saved.length, 1);
    expect(svc.stopped, isTrue);
  });

  test('finish enqueues when saver fails (offline)', () async {
    final svc = FakeRunService();
    final saver = FakeSaver()..shouldFail = true;
    final c = _build(svc: svc, saver: saver)..enterFlow();
    c.startCountdown();
    c.countdownComplete();
    c.requestStop();
    await c.finish();
    expect(c.state, RecordState.summary);
    expect(c.offlineQueued, isTrue);
  });

  test('discard from confirming returns to idle without saving', () async {
    final svc = FakeRunService();
    final saver = FakeSaver();
    final c = _build(svc: svc, saver: saver)..enterFlow();
    c.startCountdown();
    c.countdownComplete();
    c.requestStop();
    c.discard();
    expect(c.state, RecordState.idle);
    expect(saver.saved, isEmpty);
  });

  test('cancelFlow from preStart returns to idle', () {
    final c = _build()..enterFlow();
    c.cancelFlow();
    expect(c.state, RecordState.idle);
  });

  test('exitSummary returns to idle', () async {
    final c = _build()..enterFlow();
    c.startCountdown();
    c.countdownComplete();
    c.requestStop();
    await c.finish();
    c.exitSummary();
    expect(c.state, RecordState.idle);
  });

  test('reportPermissionDenied moves preStart -> error(denied)', () {
    final c = _build()..enterFlow();
    c.reportPermissionDenied(permanent: false);
    expect(c.state, RecordState.error);
    expect(c.error, RecordError.permissionDenied);
  });

  test('reportPermissionDenied permanent sets permanentlyDenied', () {
    final c = _build()..enterFlow();
    c.reportPermissionDenied(permanent: true);
    expect(c.error, RecordError.permissionPermanentlyDenied);
  });

  test('reportGpsUnavailable from preStart moves to error(gpsUnavailable)', () {
    final c = _build()..enterFlow();
    c.reportGpsUnavailable();
    expect(c.error, RecordError.gpsUnavailable);
  });

  test('error dismissal returns to idle', () {
    final c = _build()..enterFlow();
    c.reportPermissionDenied(permanent: false);
    c.dismissError();
    expect(c.state, RecordState.idle);
  });
}
