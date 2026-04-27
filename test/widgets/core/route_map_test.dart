import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trego/widgets/core/route_map.dart';
import '../../helpers/test_app.dart';

void main() {
  initTestEnv();

  setUpAll(() {
    RouteMap.builderOverride = (polyline, currentPosition, autoFollow, pins) =>
        const SizedBox.expand(child: ColoredBox(color: Color(0xFF222222)));
  });

  tearDownAll(() => RouteMap.builderOverride = null);

  testWidgets('renders the override placeholder in tests', (tester) async {
    await tester.pumpWidget(testApp(
      const SizedBox(
        width: 300,
        height: 200,
        child: RouteMap(polyline: [], autoFollow: false),
      ),
    ));
    expect(find.byType(ColoredBox), findsOneWidget);
  });

  testWidgets('accepts current position + polyline without errors', (tester) async {
    await tester.pumpWidget(testApp(
      const SizedBox(
        width: 300,
        height: 200,
        child: RouteMap(
          polyline: [LatLng(37.7749, -122.4194), LatLng(37.7750, -122.4190)],
          currentPosition: LatLng(37.7750, -122.4190),
          showStartEndPins: true,
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
