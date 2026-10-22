import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final dir = Directory(Platform.environment['MATERIAL_CAPTURE_DIR']!);
  await dir.create(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      await File('${dir.path}/$name.png').writeAsBytes(bytes);
      return true;
    },
  );
}
