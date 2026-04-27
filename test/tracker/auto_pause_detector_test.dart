import 'package:flutter_test/flutter_test.dart';
import 'package:trego/tracker/auto_pause_detector.dart';

void main() {
  late AutoPauseDetector detector;
  late List<String> events;

  setUp(() {
    events = [];
    detector = AutoPauseDetector()
      ..onPauseRequested = () {
        events.add('pause');
      }
      ..onResumeRequested = () {
        events.add('resume');
      };
  });

  test('fires pause when the full 10s window is under 1 km/h', () {
    detector.enable();
    var t = DateTime(2026, 1, 1, 12, 0, 0);
    for (var i = 0; i < 11; i++) {
      detector.addSample(0.3, t);
      t = t.add(const Duration(seconds: 1));
    }
    expect(events, ['pause']);
  });

  test('does not fire pause if any sample in window is above threshold', () {
    detector.enable();
    var t = DateTime(2026, 1, 1, 12, 0, 0);
    for (var i = 0; i < 5; i++) {
      detector.addSample(0.3, t);
      t = t.add(const Duration(seconds: 1));
    }
    detector.addSample(5.0, t); // one brisk sample breaks the stopped window
    t = t.add(const Duration(seconds: 1));
    for (var i = 0; i < 5; i++) {
      detector.addSample(0.3, t);
      t = t.add(const Duration(seconds: 1));
    }
    expect(events, isEmpty);
  });

  test('fires resume only after 3s of samples above 2 km/h', () {
    detector.enable();
    // Force pause first.
    var t = DateTime(2026, 1, 1, 12, 0, 0);
    for (var i = 0; i < 11; i++) {
      detector.addSample(0.0, t);
      t = t.add(const Duration(seconds: 1));
    }
    events.clear();

    detector.addSample(2.5, t);
    t = t.add(const Duration(seconds: 1));
    detector.addSample(2.5, t);
    t = t.add(const Duration(seconds: 1));
    expect(events, isEmpty, reason: 'only 2 of 3 seconds above threshold');

    detector.addSample(2.5, t);
    expect(events, ['resume']);
  });

  test('disable clears window and stops firing', () {
    detector.enable();
    var t = DateTime(2026, 1, 1, 12, 0, 0);
    for (var i = 0; i < 5; i++) {
      detector.addSample(0.0, t);
      t = t.add(const Duration(seconds: 1));
    }
    detector.disable();
    for (var i = 0; i < 10; i++) {
      detector.addSample(0.0, t);
      t = t.add(const Duration(seconds: 1));
    }
    expect(events, isEmpty);
  });

  test('handles window-edge correctly — exactly 10s of zeros fires once', () {
    detector.enable();
    var t = DateTime(2026, 1, 1, 12, 0, 0);
    for (var i = 0; i < 11; i++) {
      detector.addSample(0.0, t);
      t = t.add(const Duration(seconds: 1));
    }
    // Keep feeding zeros — should NOT re-fire (still paused in state's eyes).
    for (var i = 0; i < 10; i++) {
      detector.addSample(0.0, t);
      t = t.add(const Duration(seconds: 1));
    }
    expect(events.where((e) => e == 'pause').length, 1);
  });

  test('zero samples produce no events', () {
    detector.enable();
    expect(events, isEmpty);
  });
}
