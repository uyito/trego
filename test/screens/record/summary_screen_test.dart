import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trego/metrics/metrics_models.dart';
import 'package:trego/metrics/metrics_provider.dart';
import 'package:trego/screens/record/summary_screen.dart';
import 'package:trego/tracker/record_state.dart';
import 'package:trego/tracker/run_model.dart';
import 'package:trego/tracker/session_controller.dart';
import 'package:trego/widgets/core/route_map.dart';
import '../../helpers/test_app.dart';

/// Minimal MetricsProvider stand-in for tests that don't care about metrics
/// but need to pump SummaryScreen (which watches MetricsProvider).
class _NullMetricsProvider extends ChangeNotifier implements MetricsProvider {
  @override MetricsSnapshot? get snapshot => null;
  @override MetricsSnapshot? get previousSnapshot => null;
  @override bool get hasData => false;
  @override bool get loading => false;
  @override Object? get lastError => null;
  @override Future<void> refresh({Duration maxAge = const Duration(minutes: 5)}) async {}
  @override Future<void> recomputeAndRefresh() async {}
  @override void clear() {}
  @override noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Widget _wrap(Widget child, FakeSessionController c) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MetricsProvider>.value(value: _NullMetricsProvider()),
      ChangeNotifierProvider<SessionController>.value(value: c),
    ],
    child: testApp(child),
  );
}

class FakeSessionController extends ChangeNotifier implements SessionController {
  FakeSessionController({
    this.offlineQueued = false,
    this.endedByPermissionRevoke = false,
  });
  @override RecordState state = RecordState.summary;
  @override PauseReason? pauseReason;
  @override RecordError? error;
  @override bool offlineQueued;
  @override Run? lastRun;
  @override Duration elapsed = Duration.zero;
  @override double distanceKm = 0;
  @override Duration? currentPacePerKm;
  @override List<LatLng> route = const [];
  @override double? currentAccuracyMeters;
  final bool endedByPermissionRevoke;

  bool exitCalled = false;
  @override void exitSummary() { exitCalled = true; }
  @override noSuchMethod(Invocation i) => super.noSuchMethod(i);

  void fill({required Run run}) { lastRun = run; notifyListeners(); }
}

Run _run({bool revoke = false}) => Run(
      userId: 'u',
      startTime: DateTime(2026, 4, 19, 8, 4),
      endTime: DateTime(2026, 4, 19, 8, 28, 13),
      duration: const Duration(minutes: 24, seconds: 13),
      distance: 5.20,
      averagePace: 4.633, // minutes per km ≈ 4:38
      route: const [LatLng(0, 0), LatLng(0.01, 0.01)],
      endedByPermissionRevoke: revoke,
    );

void main() {
  initTestEnv();

  setUpAll(() => RouteMap.builderOverride = (_, __, ___, ____) => const SizedBox());
  tearDownAll(() => RouteMap.builderOverride = null);

  testWidgets('renders title + hero stats', (tester) async {
    final c = FakeSessionController()..fill(run: _run());
    await tester.pumpWidget(_wrap(const SummaryScreen(), c));
    expect(find.text('Morning Run'), findsOneWidget);
    expect(find.text('5.20'), findsOneWidget);
    expect(find.text('24:13'), findsOneWidget);
  });

  testWidgets('shows offline banner when offlineQueued is true', (tester) async {
    final c = FakeSessionController(offlineQueued: true)..fill(run: _run());
    await tester.pumpWidget(_wrap(const SummaryScreen(), c));
    expect(find.textContaining('Offline'), findsOneWidget);
  });

  testWidgets('× invokes exitSummary', (tester) async {
    final c = FakeSessionController()..fill(run: _run());
    await tester.pumpWidget(_wrap(const SummaryScreen(), c));
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(c.exitCalled, isTrue);
  });

  testWidgets('SHARE invokes OS share sheet with run text', (tester) async {
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final c = FakeSessionController()..fill(run: _run());
    await tester.pumpWidget(_wrap(const SummaryScreen(), c));
    await tester.tap(find.text('SHARE'));
    await tester.pump();

    expect(calls, isNotEmpty);
    final args = calls.first.arguments as Map;
    expect(args['text'], contains('Morning Run'));
    expect(args['text'], contains('5.20 km'));
    expect(args['subject'], 'Morning Run');
  });
}
