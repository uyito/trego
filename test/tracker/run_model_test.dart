import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trego/tracker/run_model.dart';

void main() {
  test('PausedInterval round-trips via Map', () {
    final iv = PausedInterval(
      start: DateTime.fromMillisecondsSinceEpoch(1000),
      end: DateTime.fromMillisecondsSinceEpoch(5000),
    );
    final back = PausedInterval.fromMap(iv.toMap());
    expect(back.start, iv.start);
    expect(back.end, iv.end);
  });

  test('Run defaults pausedIntervals to empty and endedByPermissionRevoke to false', () {
    final run = Run(
      userId: 'u',
      startTime: DateTime.fromMillisecondsSinceEpoch(0),
      duration: Duration(seconds: 60),
      distance: 1.0,
      averagePace: 6.0,
      route: const [],
    );
    expect(run.pausedIntervals, isEmpty);
    expect(run.endedByPermissionRevoke, isFalse);
  });

  test('Run.fromMap handles missing new fields (backward compatible)', () {
    final legacyMap = <String, dynamic>{
      'userId': 'u',
      'startTime': Timestamp.fromDate(DateTime.fromMillisecondsSinceEpoch(0)),
      'endTime': Timestamp.fromDate(DateTime.fromMillisecondsSinceEpoch(60000)),
      'durationSeconds': 60,
      'distance': 1.0,
      'averagePace': 6.0,
      'route': <Map<String, dynamic>>[],
    };
    final run = Run.fromMap(legacyMap, 'doc-id');
    expect(run.pausedIntervals, isEmpty);
    expect(run.endedByPermissionRevoke, isFalse);
  });

  test('Run serializes and deserializes new fields', () {
    final run = Run(
      userId: 'u',
      startTime: DateTime.fromMillisecondsSinceEpoch(0),
      endTime: DateTime.fromMillisecondsSinceEpoch(60000),
      duration: Duration(seconds: 60),
      distance: 1.0,
      averagePace: 6.0,
      route: const [],
      pausedIntervals: [
        PausedInterval(
          start: DateTime.fromMillisecondsSinceEpoch(10000),
          end: DateTime.fromMillisecondsSinceEpoch(20000),
        ),
      ],
      endedByPermissionRevoke: true,
    );
    final map = run.toMap();
    final back = Run.fromMap(map, 'doc-id');
    expect(back.pausedIntervals.length, 1);
    expect(back.endedByPermissionRevoke, isTrue);
  });
}
