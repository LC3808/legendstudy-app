import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Existing shell tests never start a session; platform I/O must not depend on a device.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('com.legendstudy.app/study'),
        (call) async {
          if (call.method == 'clock') {
            return {
              'utcMs': 1789344000000,
              'elapsedMs': 100000,
              'boot': 'test-boot',
            };
          }
          if (call.method == 'read') return null;
          if (call.method == 'write') return null;
          throw MissingPluginException();
        },
      );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('com.legendstudy.app/focus'),
        (call) async {
          if (call.method == 'status') {
            return {'capability': 'unsupported', 'permission': false};
          }
          if (call.method == 'readPreference') return 'ask';
          return null;
        },
      );
  await testMain();
}
