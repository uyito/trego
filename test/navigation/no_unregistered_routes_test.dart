// Guard test: every Navigator.pushNamed(...) target used anywhere in lib/
// must be a route registered in lib/app.dart's MaterialApp.routes map.
//
// This is a plain source-scan test (dart:io + regex), not a widget test,
// so it can catch dead/unregistered route strings without needing to boot
// the full app.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no Navigator.pushNamed call targets an unregistered route', () {
    final appDartFile = File('lib/app.dart');
    expect(appDartFile.existsSync(), isTrue,
        reason: 'lib/app.dart must exist');
    final appDartContents = appDartFile.readAsStringSync();

    // Collect the registered route names from MaterialApp.routes, i.e.
    // string-literal keys like '/login': (context) => ...
    final routesBlockMatch =
        RegExp(r'routes:\s*\{([\s\S]*?)\n\s*\},').firstMatch(appDartContents);
    expect(routesBlockMatch, isNotNull,
        reason: 'Could not find routes: { ... } block in lib/app.dart');
    final routesBlock = routesBlockMatch!.group(1)!;

    final registeredRoutes = RegExp(r"""['"](/[^'"]*)['"]\s*:""")
        .allMatches(routesBlock)
        .map((m) => m.group(1)!)
        .toSet();

    expect(registeredRoutes, isNotEmpty,
        reason: 'Expected at least one registered route in lib/app.dart');

    // Scan all lib/**/*.dart files for Navigator.pushNamed(context, '...')
    // and .pushNamed('...') calls, extracting the route-name string literal.
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue);

    final pushNamedPattern = RegExp(
      r"""\.pushNamed\(\s*(?:context\s*,\s*)?['"]([^'"]+)['"]""",
    );

    final unregistered = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final contents = entity.readAsStringSync();
      for (final match in pushNamedPattern.allMatches(contents)) {
        final route = match.group(1)!;
        if (!registeredRoutes.contains(route)) {
          unregistered.add('${entity.path} -> "$route"');
        }
      }
    }

    expect(
      unregistered,
      isEmpty,
      reason:
          'Found Navigator.pushNamed call(s) targeting unregistered route(s):\n'
          '${unregistered.join('\n')}\n'
          'Registered routes: $registeredRoutes',
    );
  });
}
