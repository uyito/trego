import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trego/screens/record/countdown_overlay.dart';
import 'package:trego/tracker/record_state.dart';
import 'package:trego/tracker/run_model.dart' show LatLng, Run;
import 'package:trego/tracker/session_controller.dart';
import '../../helpers/test_app.dart';

class FakeSessionController extends ChangeNotifier implements SessionController {
  @override RecordState state = RecordState.countdown;
  @override PauseReason? pauseReason;
  @override RecordError? error;
  @override bool offlineQueued = false;
  @override Run? lastRun;
  @override Duration elapsed = Duration.zero;
  @override double distanceKm = 0;
  @override Duration? currentPacePerKm;
  @override List<LatLng> route = const [];
  @override double? currentAccuracyMeters;
  bool countdownCompleteCalled = false;
  bool cancelCountdownCalled = false;
  @override void countdownComplete() { countdownCompleteCalled = true; }
  @override void cancelCountdown() { cancelCountdownCalled = true; }
  @override noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  initTestEnv();

  testWidgets('counts 3 → 2 → 1 then calls countdownComplete', (tester) async {
    final c = FakeSessionController();
    await tester.pumpWidget(ChangeNotifierProvider<SessionController>.value(
      value: c,
      child: testApp(const CountdownOverlay()),
    ));
    expect(find.text('3'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(c.countdownCompleteCalled, isTrue);
  });

  testWidgets('× cancels the countdown', (tester) async {
    final c = FakeSessionController();
    await tester.pumpWidget(ChangeNotifierProvider<SessionController>.value(
      value: c,
      child: testApp(const CountdownOverlay()),
    ));
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(c.cancelCountdownCalled, isTrue);
  });
}
