import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard test: ensures the legacy `AppTheme` class and its file
/// (`lib/shared/app_theme.dart`) have been fully retired from the codebase.
///
/// This test is deterministic — it walks `lib/` on disk and does plain
/// string matching, no build/analysis tooling involved.
void main() {
  test('no .dart file under lib/ references AppTheme', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib/ directory must exist');

    final offendingFiles = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      final contents = entity.readAsStringSync();
      if (contents.contains('AppTheme')) {
        offendingFiles.add(entity.path);
      }
    }

    expect(
      offendingFiles,
      isEmpty,
      reason:
          'The following files still reference AppTheme and must be updated '
          'or removed: ${offendingFiles.join(', ')}',
    );
  });

  test('lib/shared/app_theme.dart no longer exists', () {
    final file = File('lib/shared/app_theme.dart');
    expect(
      file.existsSync(),
      isFalse,
      reason: 'lib/shared/app_theme.dart should have been deleted',
    );
  });
}
