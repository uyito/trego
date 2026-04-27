import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trego/screens/record/live_record_screen.dart';
import 'package:trego/tracker/record_state.dart';
import 'package:trego/tracker/run_model.dart' show LatLng, Run;
import 'package:trego/tracker/session_controller.dart';
import 'package:trego/widgets/core/route_map.dart';
import '../../helpers/test_app.dart';

class FakeSessionController extends ChangeNotifier implements SessionController {
  FakeSessionController({this.state = RecordState.recording, this.pauseReason});
  @override RecordState state;
  @override PauseReason? pauseReason;
  @override RecordError? error;
  @override bool offlineQueued = false;
  @override Run? lastRun;
  @override Duration elapsed = const Duration(minutes: 14, seconds: 32);
  @override double distanceKm = 2.4;
  @override Duration? currentPacePerKm = const Duration(minutes: 6, seconds: 3);
  @override List<LatLng> route = const [];
  @override double? currentAccuracyMeters = 4;
  bool pauseCalled = false, resumeCalled = false, stopCalled = false;
  @override void pauseManual() { pauseCalled = true; state = RecordState.paused; pauseReason = PauseReason.manual; notifyListeners(); }
  @override void resume() { resumeCalled = true; state = RecordState.recording; pauseReason = null; notifyListeners(); }
  @override void requestStop() { stopCalled = true; }
  @override noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  initTestEnv();

  setUpAll(() {
    RouteMap.builderOverride = (_, __, ___, ____) => const SizedBox.expand();
  });
  tearDownAll(() => RouteMap.builderOverride = null);

  testWidgets('recording state shows Time, km, pace, kcal + Pause button', (tester) async {
    final c = FakeSessionController();
    await tester.pumpWidget(ChangeNotifierProvider<SessionController>.value(
      value: c,
      child: testApp(const LiveRecordScreen()),
    ));
    expect(find.text('14:32'), findsOneWidget);
    expect(find.text('2.40'), findsOneWidget);
    expect(find.text('06:03'), findsOneWidget);
    expect(find.textContaining('PAUSE'), findsOneWidget);
  });

  testWidgets('tapping Pause invokes pauseManual', (tester) async {
    final c = FakeSessionController();
    await tester.pumpWidget(ChangeNotifierProvider<SessionController>.value(
      value: c,
      child: testApp(const LiveRecordScreen()),
    ));
    await tester.tap(find.textContaining('PAUSE'));
    await tester.pumpAndSettle();
    expect(c.pauseCalled, isTrue);
  });

  testWidgets('paused state shows Paused banner + Resume button', (tester) async {
    final c = FakeSessionController(state: RecordState.paused, pauseReason: PauseReason.manual);
    await tester.pumpWidget(ChangeNotifierProvider<SessionController>.value(
      value: c,
      child: testApp(const LiveRecordScreen()),
    ));
    expect(find.text('Paused'), findsOneWidget);
    expect(find.textContaining('RESUME'), findsOneWidget);
  });
}
