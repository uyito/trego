import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trego/tracker/pending_saves_flusher.dart';
import 'package:trego/tracker/run_model.dart';

class FakeRunSaver implements RunSaver {
  final List<Run> saved = [];
  bool shouldFail = false;

  @override
  Future<void> save(Run run) async {
    if (shouldFail) throw Exception('no net');
    saved.add(run);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Run _r(int stamp) => Run(
        userId: 'u',
        startTime: DateTime.fromMillisecondsSinceEpoch(stamp),
        endTime: DateTime.fromMillisecondsSinceEpoch(stamp + 60000),
        duration: const Duration(milliseconds: 60000),
        distance: 1.0,
        averagePace: 6.0,
        route: const <LatLng>[],
      );

  test('enqueue persists to SharedPreferences', () async {
    final saver = FakeRunSaver();
    final flusher = PendingSavesFlusher(saver: saver);
    await flusher.enqueue(_r(0));
    expect(flusher.pendingCount, 1);
  });

  test('flush saves all queued runs and clears them on success', () async {
    final saver = FakeRunSaver();
    final flusher = PendingSavesFlusher(saver: saver);
    await flusher.enqueue(_r(0));
    await flusher.enqueue(_r(1));
    final n = await flusher.flush();
    expect(n, 2);
    expect(saver.saved.length, 2);
    expect(flusher.pendingCount, 0);
  });

  test('flush keeps runs in queue if save fails', () async {
    final saver = FakeRunSaver()..shouldFail = true;
    final flusher = PendingSavesFlusher(saver: saver);
    await flusher.enqueue(_r(0));
    final n = await flusher.flush();
    expect(n, 0);
    expect(flusher.pendingCount, 1);
  });

  test('queue is capped at 20 entries', () async {
    final saver = FakeRunSaver();
    final flusher = PendingSavesFlusher(saver: saver);
    for (var i = 0; i < 25; i++) {
      await flusher.enqueue(_r(i));
    }
    expect(flusher.pendingCount, 20);
  });

  test('flush-empty returns 0 without error', () async {
    final saver = FakeRunSaver();
    final flusher = PendingSavesFlusher(saver: saver);
    expect(await flusher.flush(), 0);
  });
}
