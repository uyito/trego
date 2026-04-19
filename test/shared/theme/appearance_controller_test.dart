import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trego/shared/theme/appearance_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to system when no stored preference', () async {
    final controller = AppearanceController();
    await controller.load();
    expect(controller.mode, ThemeMode.system);
  });

  test('loads stored light preference', () async {
    SharedPreferences.setMockInitialValues({'appearance.mode': 'light'});
    final controller = AppearanceController();
    await controller.load();
    expect(controller.mode, ThemeMode.light);
  });

  test('loads stored dark preference', () async {
    SharedPreferences.setMockInitialValues({'appearance.mode': 'dark'});
    final controller = AppearanceController();
    await controller.load();
    expect(controller.mode, ThemeMode.dark);
  });

  test('ignores invalid stored value (fallback system)', () async {
    SharedPreferences.setMockInitialValues({'appearance.mode': 'banana'});
    final controller = AppearanceController();
    await controller.load();
    expect(controller.mode, ThemeMode.system);
  });

  test('setMode persists and notifies listeners', () async {
    final controller = AppearanceController();
    await controller.load();
    var notifyCount = 0;
    controller.addListener(() => notifyCount++);

    await controller.setMode(ThemeMode.dark);
    expect(controller.mode, ThemeMode.dark);
    expect(notifyCount, 1);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('appearance.mode'), 'dark');
  });

  test('setMode to same value does not notify', () async {
    final controller = AppearanceController();
    await controller.load();
    var notifyCount = 0;
    controller.addListener(() => notifyCount++);

    await controller.setMode(ThemeMode.system);
    expect(notifyCount, 0);
  });

  test('load() notifies listeners when stored preference differs from default', () async {
    SharedPreferences.setMockInitialValues({'appearance.mode': 'dark'});
    final controller = AppearanceController();
    var notifyCount = 0;
    controller.addListener(() => notifyCount++);

    await controller.load();

    expect(controller.mode, ThemeMode.dark);
    expect(notifyCount, 1, reason: 'Consumers must be told to rebuild once the stored pref resolves');
  });

  test('load() does not notify when stored preference matches default', () async {
    // No stored value → parses to system (the initial _mode).
    final controller = AppearanceController();
    var notifyCount = 0;
    controller.addListener(() => notifyCount++);

    await controller.load();

    expect(controller.mode, ThemeMode.system);
    expect(notifyCount, 0, reason: 'No change → no rebuild churn');
  });
}
