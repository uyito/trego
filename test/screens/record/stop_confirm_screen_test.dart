import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trego/screens/record/stop_confirm_screen.dart';
import 'package:trego/tracker/record_state.dart';
import 'package:trego/tracker/run_model.dart' show LatLng, Run;
import 'package:trego/tracker/session_controller.dart';
import '../../helpers/test_app.dart';

class FakeSessionController extends ChangeNotifier implements SessionController {
  @override RecordState state = RecordState.confirming;
  @override PauseReason? pauseReason;
  @override RecordError? error;
  @override bool offlineQueued = false;
  @override Run? lastRun;
  @override Duration elapsed = const Duration(minutes: 14, seconds: 32);
  @override double distanceKm = 2.4;
  @override Duration? currentPacePerKm = const Duration(minutes: 6, seconds: 3);
  @override List<LatLng> route = const [];
  @override double? currentAccuracyMeters = 4;
  bool resumeCalled = false, finishCalled = false, discardCalled = false;
  @override void resume() { resumeCalled = true; }
  @override Future<void> finish() async { finishCalled = true; }
  @override void discard() { discardCalled = true; }
  @override noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  initTestEnv();

  testWidgets('shows mini summary + Resume / Finish / Discard', (tester) async {
    final c = FakeSessionController();
    await tester.pumpWidget(ChangeNotifierProvider<SessionController>.value(
      value: c,
      child: testApp(const StopConfirmScreen()),
    ));
    expect(find.text('14:32'), findsOneWidget);
    expect(find.text('2.40'), findsOneWidget);
    expect(find.textContaining('RESUME'), findsOneWidget);
    expect(find.textContaining('FINISH'), findsOneWidget);
    expect(find.text('Discard run'), findsOneWidget);
  });

  testWidgets('Resume invokes controller.resume()', (tester) async {
    final c = FakeSessionController();
    await tester.pumpWidget(ChangeNotifierProvider<SessionController>.value(
      value: c,
      child: testApp(const StopConfirmScreen()),
    ));
    await tester.tap(find.textContaining('RESUME'));
    await tester.pumpAndSettle();
    expect(c.resumeCalled, isTrue);
  });

  testWidgets('Finish invokes controller.finish()', (tester) async {
    final c = FakeSessionController();
    await tester.pumpWidget(ChangeNotifierProvider<SessionController>.value(
      value: c,
      child: testApp(const StopConfirmScreen()),
    ));
    await tester.tap(find.textContaining('FINISH'));
    await tester.pumpAndSettle();
    expect(c.finishCalled, isTrue);
  });

  testWidgets('Discard requires 2-step confirm', (tester) async {
    final c = FakeSessionController();
    await tester.pumpWidget(ChangeNotifierProvider<SessionController>.value(
      value: c,
      child: testApp(const StopConfirmScreen()),
    ));
    await tester.tap(find.text('Discard run'));
    await tester.pumpAndSettle();
    expect(c.discardCalled, isFalse,
        reason: 'First tap opens confirmation dialog, does not discard');
    // Expect a dialog to appear
    expect(find.textContaining('Discard this run?'), findsOneWidget);

    await tester.tap(find.text('DISCARD'));
    await tester.pumpAndSettle();
    expect(c.discardCalled, isTrue);
  });
}
