import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/widgets/core/big_stat.dart';
import '../../helpers/test_app.dart';

void main() {
  initTestEnv();

  testWidgets('renders value and label', (tester) async {
    await tester.pumpWidget(testApp(
      const Center(child: BigStat(value: '14:32', label: 'Time')),
    ));
    expect(find.text('14:32'), findsOneWidget);
    expect(find.text('TIME'), findsOneWidget);
  });

  testWidgets('xl uses statLarge typography (44pt)', (tester) async {
    await tester.pumpWidget(testApp(
      const Center(child: BigStat(value: '5.20', label: 'km', size: BigStatSize.xl)),
    ));
    final text = tester.widget<Text>(find.text('5.20'));
    expect(text.style?.fontSize, 44);
  });

  testWidgets('golden: three sizes dark', (tester) async {
    await tester.pumpWidget(testApp(
      const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BigStat(value: '5.20', label: 'km', size: BigStatSize.xl),
            SizedBox(height: 12),
            BigStat(value: '14:32', label: 'Time', size: BigStatSize.l),
            SizedBox(height: 12),
            BigStat(value: '4:38', label: '/km pace', size: BigStatSize.m),
          ],
        ),
      ),
    ));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../goldens/big_stat_dark.png'),
    );
  });

  testWidgets('golden: three sizes light', (tester) async {
    await tester.pumpWidget(testApp(
      const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BigStat(value: '5.20', label: 'km', size: BigStatSize.xl),
            SizedBox(height: 12),
            BigStat(value: '14:32', label: 'Time', size: BigStatSize.l),
            SizedBox(height: 12),
            BigStat(value: '4:38', label: '/km pace', size: BigStatSize.m),
          ],
        ),
      ),
      mode: ThemeMode.light,
    ));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../goldens/big_stat_light.png'),
    );
  });
}
