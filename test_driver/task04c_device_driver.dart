import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final d = Directory(
      Platform.environment['TASK04C_EVIDENCE_DIR'] ?? 'build/task04c-device',
    )..createSync(recursive: true);
    await File('${d.path}/$name.png').writeAsBytes(bytes);
    return true;
  },
  responseDataCallback: (data) async {
    final d = Directory(
      Platform.environment['TASK04C_EVIDENCE_DIR'] ?? 'build/task04c-device',
    )..createSync(recursive: true);
    await File(
      '${d.path}/${Platform.environment['TASK04C_EVIDENCE_TAG'] ?? 'guest'}-report.json',
    ).writeAsString(jsonEncode(data));
  },
);
