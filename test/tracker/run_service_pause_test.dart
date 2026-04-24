import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trego/tracker/run_service.dart';

void main() {
  test('pause cancels the subscription so buffered points do not accumulate',
      () async {
    // Queue of stream controllers — startRun consumes the first, resumeRun
    // consumes the second. The factory is invoked fresh each time the
    // service subscribes (start and resume), simulating a real device where
    // cancelling a Geolocator subscription stops point production entirely.
    final firstController = StreamController<Position>();
    final secondController = StreamController<Position>();
    final factories = <StreamController<Position>>[
      firstController,
      secondController,
    ];
    final service = RunService.testable(
      positionStreamFactory: () => factories.removeAt(0).stream,
    );

    final started = await service.startRun();
    expect(started, isTrue);

    // Emit a baseline point.
    firstController.add(_fakePosition(lat: 0.0, lng: 0.0, t: 0));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await service.pauseRun();

    // These points should NOT accumulate because the subscription has been
    // cancelled (not merely paused/buffered).
    firstController.add(_fakePosition(lat: 0.01, lng: 0.01, t: 10));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final distAfterPause = service.currentDistanceKm;

    await service.resumeRun();

    // A point on the resumed stream SHOULD accumulate — resume creates a
    // fresh subscription via the injected factory.
    secondController.add(_fakePosition(lat: 0.02, lng: 0.02, t: 20));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(service.currentDistanceKm, greaterThan(distAfterPause));

    await service.stopRun();
    await firstController.close();
    await secondController.close();
  });
}

Position _fakePosition({
  required double lat,
  required double lng,
  required int t,
}) =>
    Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.fromMillisecondsSinceEpoch(t * 1000),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
