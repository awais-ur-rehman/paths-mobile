import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    final aggregate =
        data?['task13'] ?? {'status': 'failed-before-measurement'};
    final file = File('artifacts/task13/journey.local.json');
    await file.parent.create(recursive: true);
    await file.writeAsString('${jsonEncode(aggregate)}\n');
    if (!Platform.isWindows) {
      final result = await Process.run('chmod', ['600', file.path]);
      if (result.exitCode != 0) {
        throw StateError('Could not protect local measurement file');
      }
    }
  },
  writeResponseOnFailure: true,
);
