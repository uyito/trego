import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/widgets/core/gps_status_indicator.dart';
import '../../helpers/test_app.dart';

void main() {
  initTestEnv();

  testWidgets('acquiring shows "Acquiring GPS…"', (tester) async {
    await tester.pumpWidget(testApp(
      const Center(child: GpsStatusIndicator(status: GpsStatus.acquiring)),
    ));
    expect(find.text('Acquiring GPS…'), findsOneWidget);
  });

  testWidgets('weak shows "GPS — ±{n} m"', (tester) async {
    await tester.pumpWidget(testApp(
      const Center(
        child: GpsStatusIndicator(status: GpsStatus.weak, accuracyMeters: 42),
      ),
    ));
    expect(find.text('GPS — ±42 m'), findsOneWidget);
  });

  testWidgets('ready shows "GPS — ±{n} m"', (tester) async {
    await tester.pumpWidget(testApp(
      const Center(
        child: GpsStatusIndicator(status: GpsStatus.ready, accuracyMeters: 4),
      ),
    ));
    expect(find.text('GPS — ±4 m'), findsOneWidget);
  });

  testWidgets('golden: three states dark', (tester) async {
    await tester.pumpWidget(testApp(
      const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GpsStatusIndicator(status: GpsStatus.acquiring),
            SizedBox(height: 12),
            GpsStatusIndicator(status: GpsStatus.weak, accuracyMeters: 42),
            SizedBox(height: 12),
            GpsStatusIndicator(status: GpsStatus.ready, accuracyMeters: 4),
          ],
        ),
      ),
    ));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../goldens/gps_status_indicator_dark.png'),
    );
  });

  testWidgets('golden: three states light', (tester) async {
    await tester.pumpWidget(testApp(
      const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GpsStatusIndicator(status: GpsStatus.acquiring),
            SizedBox(height: 12),
            GpsStatusIndicator(status: GpsStatus.weak, accuracyMeters: 42),
            SizedBox(height: 12),
            GpsStatusIndicator(status: GpsStatus.ready, accuracyMeters: 4),
          ],
        ),
      ),
      mode: ThemeMode.light,
    ));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../goldens/gps_status_indicator_light.png'),
    );
  });
}
