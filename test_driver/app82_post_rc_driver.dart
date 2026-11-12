import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final dir = Directory(
      Platform.environment['POST_RC_EVIDENCE_DIR'] ?? 'build/post-rc-native',
    )..createSync(recursive: true);
    await File('${dir.path}/$name.png').writeAsBytes(bytes);
    return true;
  },
  responseDataCallback: (data) async {
    final dir = Directory(
      Platform.environment['POST_RC_EVIDENCE_DIR'] ?? 'build/post-rc-native',
    )..createSync(recursive: true);
    // Screenshots are stored separately; do not duplicate image bytes in JSON.
    await File('${dir.path}/report.json').writeAsString(
      jsonEncode({
        for (final entry in (data ?? {}).entries)
          if (entry.key != 'screenshots') entry.key: entry.value,
      }),
    );
  },
);
