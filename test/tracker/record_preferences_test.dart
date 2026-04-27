import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trego/tracker/record_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('default autoPauseEnabled is true when no stored value', () async {
    final prefs = RecordPreferences();
    await prefs.load();
    expect(prefs.autoPauseEnabled, isTrue);
  });

  test('load reads stored false', () async {
    SharedPreferences.setMockInitialValues({'recording.autoPause': false});
    final prefs = RecordPreferences();
    await prefs.load();
    expect(prefs.autoPauseEnabled, isFalse);
  });

  test('setAutoPauseEnabled persists and notifies when changed', () async {
    final prefs = RecordPreferences();
    await prefs.load();
    var notifyCount = 0;
    prefs.addListener(() => notifyCount++);

    await prefs.setAutoPauseEnabled(false);

    expect(prefs.autoPauseEnabled, isFalse);
    expect(notifyCount, 1);
    final stored = await SharedPreferences.getInstance();
    expect(stored.getBool('recording.autoPause'), isFalse);
  });

  test('setAutoPauseEnabled is a no-op on same value', () async {
    final prefs = RecordPreferences();
    await prefs.load();
    var notifyCount = 0;
    prefs.addListener(() => notifyCount++);

    await prefs.setAutoPauseEnabled(true); // default is already true

    expect(notifyCount, 0);
  });
}
