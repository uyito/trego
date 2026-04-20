import 'package:flutter_test/flutter_test.dart';
import 'package:trego/providers/plan_provider.dart';

void main() {
  test('today() returns null by default', () {
    final p = PlanProvider();
    expect(p.today(), isNull);
  });

  test('progressSummary returns null by default', () {
    final p = PlanProvider();
    expect(p.progressSummary(), isNull);
  });
}
