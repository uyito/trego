import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trego/screens/record/pre_start_screen.dart';
import 'package:trego/tracker/record_state.dart';
import 'package:trego/tracker/run_model.dart' show LatLng, Run;
import 'package:trego/tracker/session_controller.dart';
import '../../helpers/test_app.dart';

/// Fake SessionController that mutates its own state directly for tests.
class FakeSessionController extends ChangeNotifier implements SessionController {
  @override RecordState state = RecordState.preStart;
  @override PauseReason? pauseReason;
  @override RecordError? error;
  @override bool offlineQueued = false;
  @override Run? lastRun;
  @override Duration elapsed = Duration.zero;
  @override double distanceKm = 0;
  @override Duration? currentPacePerKm;
  @override List<LatLng> route = const [];
  @override double? currentAccuracyMeters;

  bool startCountdownCalled = false;
  bool cancelFlowCalled = false;

  @override void startCountdown() { startCountdownCalled = true; }
  @override void cancelFlow() { cancelFlowCalled = true; }

  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  initTestEnv();

  testWidgets('shows GPS acquiring state with disabled Start', (tester) async {
    final c = FakeSessionController();
    await tester.pumpWidget(ChangeNotifierProvider<SessionController>.value(
      value: c,
      child: testApp(const PreStartScreen(gpsAccuracyMeters: null)),
    ));
    expect(find.text('Acquiring GPS…'), findsOneWidget);
    expect(find.text('START RUN'), findsOneWidget);

    await tester.tap(find.text('START RUN'));
    await tester.pumpAndSettle();
    expect(c.startCountdownCalled, isFalse,
        reason: 'Start should be disabled while GPS is acquiring');
  });

  testWidgets('shows GPS ready and Start invokes startCountdown', (tester) async {
    final c = FakeSessionController();
    await tester.pumpWidget(ChangeNotifierProvider<SessionController>.value(
      value: c,
      child: testApp(const PreStartScreen(gpsAccuracyMeters: 4)),
    ));
    expect(find.textContaining('GPS — ±4 m'), findsOneWidget);

    await tester.tap(find.text('START RUN'));
    await tester.pumpAndSettle();
    expect(c.startCountdownCalled, isTrue);
  });
}
